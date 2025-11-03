using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.ML;
using Microsoft.ML.Trainers;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Worker.Services
{
    // Service for training ML recommendation models using Matrix Factorization algorithm
    public class MLTrainingService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<MLTrainingService> _logger;
        private readonly string _modelStoragePath;

        public MLTrainingService(
            ApplicationDbContext context,
            ILogger<MLTrainingService> logger,
            IConfiguration configuration)
        {
            _context = context;
            _logger = logger;
            _modelStoragePath = configuration["MLModelStoragePath"] ?? Path.Combine(Directory.GetCurrentDirectory(), "MLModels");
            
            // Ensure model storage directory exists
            Directory.CreateDirectory(_modelStoragePath);
        }

        // Trains a new ML recommendation model using all available order data
        public async Task<bool> TrainModelAsync()
        {
            try
            {
                _logger.LogInformation("Starting ML recommendation model training...");

                var trainingData = await PrepareTrainingDataAsync();
                
                if (trainingData.Count < 10)
                {
                    _logger.LogWarning("Not enough training data (minimum 10 interactions required). Current count: {Count}", trainingData.Count);
                    return false;
                }

                _logger.LogInformation("Prepared {Count} training samples", trainingData.Count);

                var mlContext = new MLContext(seed: 0);
                var dataView = mlContext.Data.LoadFromEnumerable(trainingData);
                var dataSplit = mlContext.Data.TrainTestSplit(dataView, testFraction: 0.2);

                _logger.LogInformation("Building Matrix Factorization pipeline...");
                var options = new MatrixFactorizationTrainer.Options
                {
                    MatrixColumnIndexColumnName = "UserId",
                    MatrixRowIndexColumnName = "ToolId",
                    LabelColumnName = "Label",
                    NumberOfIterations = 20,
                    ApproximationRank = 100,
                    Quiet = false
                };

                var pipeline = mlContext.Transforms.Conversion.MapValueToKey("UserId", "UserId")
                    .Append(mlContext.Transforms.Conversion.MapValueToKey("ToolId", "ToolId"))
                    .Append(mlContext.Recommendation().Trainers.MatrixFactorization(options));

                _logger.LogInformation("Training model... This may take a few minutes.");
                var model = pipeline.Fit(dataSplit.TrainSet);

                var predictions = model.Transform(dataSplit.TestSet);
                var metrics = mlContext.Regression.Evaluate(predictions, labelColumnName: "Label");

                _logger.LogInformation("Model training completed!");
                _logger.LogInformation("Model Metrics - RMSE: {RMSE:F4}, RSquared: {RSquared:F4}", 
                    metrics.RootMeanSquaredError, metrics.RSquared);
                var modelFileName = $"recommendation_model_{DateTime.UtcNow:yyyyMMdd_HHmmss}.zip";
                var modelPath = Path.Combine(_modelStoragePath, modelFileName);

                mlContext.Model.Save(model, dataView.Schema, modelPath);
                var fileInfo = new FileInfo(modelPath);

                _logger.LogInformation("Model saved to: {Path} (Size: {Size} bytes)", modelPath, fileInfo.Length);

                await SaveModelMetadataAsync(modelFileName, modelPath, trainingData.Count, metrics, fileInfo.Length);

                _logger.LogInformation("ML model training completed successfully!");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error training ML recommendation model");
                return false;
            }
        }

        // Prepares training data from order history with implicit ratings based on rental patterns
        private async Task<List<ToolRating>> PrepareTrainingDataAsync()
        {
            var orderData = await _context.Set<Order>()
                .SelectMany(o => o.OrderItems.Select(oi => new
                {
                    UserId = o.UserId,
                    ToolId = oi.ToolId,
                    OrderDate = o.CreatedAt,
                    RentalDays = (int)(o.EndDate - o.StartDate).TotalDays,
                    IsReturned = o.IsReturned
                }))
                .ToListAsync();

            var ratings = orderData
                .GroupBy(x => new { x.UserId, x.ToolId })
                .Select(g => new ToolRating
                {
                    UserId = g.Key.UserId,
                    ToolId = g.Key.ToolId,
                    Label = CalculateImplicitRating(
                        g.Count(), 
                        g.Max(x => x.RentalDays), 
                        g.Max(x => x.OrderDate),
                        g.Any(x => x.IsReturned))
                })
                .ToList();

            return ratings;
        }

        // Calculates implicit rating (1-5) based on rental frequency, duration, recency, and return status
        private float CalculateImplicitRating(int rentalCount, int maxRentalDays, DateTime lastRentalDate, bool wasReturned)
        {
            float rating = Math.Min(rentalCount * 1.5f, 5.0f);

            if (maxRentalDays >= 7)
                rating = Math.Min(rating + 0.5f, 5.0f);

            var daysSinceLastRental = (DateTime.UtcNow - lastRentalDate).TotalDays;
            if (daysSinceLastRental <= 30)
                rating = Math.Min(rating + 0.3f, 5.0f);

            if (wasReturned)
                rating = Math.Min(rating + 0.2f, 5.0f);

            return Math.Max(rating, 1.0f);
        }

        // Saves model metadata to database and marks it as active
        private async Task SaveModelMetadataAsync(
            string modelName, 
            string modelPath, 
            int trainingDataSize, 
            Microsoft.ML.Data.RegressionMetrics metrics,
            long fileSizeBytes)
        {
            var previousModels = await _context.MLRecommendationModels.ToListAsync();
            foreach (var oldModel in previousModels)
            {
                oldModel.IsActive = false;
            }
            var newModel = new MLRecommendationModel
            {
                ModelName = modelName,
                ModelFilePath = modelPath,
                TrainingDataSize = trainingDataSize,
                TrainedAt = DateTime.UtcNow,
                IsActive = true,
                ModelFileSizeBytes = fileSizeBytes,
                TrainingMetrics = $"RMSE: {metrics.RootMeanSquaredError:F4}, RSquared: {metrics.RSquared:F4}, MAE: {metrics.MeanAbsoluteError:F4}"
            };

            _context.MLRecommendationModels.Add(newModel);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Model metadata saved to database");
        }

        // Checks if training should run based on engine settings and last training date
        public async Task<bool> ShouldTrainAsync()
        {
            var settings = await _context.RecommendationSettings.FirstOrDefaultAsync();
            if (settings == null)
                return false;

            if (settings.Engine == RecommendationEngine.RuleBased)
                return false;

            if (settings.LastTrainingDate == null)
                return true;

            var daysSinceLastTraining = (DateTime.UtcNow - settings.LastTrainingDate.Value).TotalDays;
            return daysSinceLastTraining >= settings.TrainingIntervalDays;
        }

        // Updates the last training date in settings after successful training
        public async Task UpdateLastTrainingDateAsync()
        {
            var settings = await _context.RecommendationSettings.FirstOrDefaultAsync();
            if (settings != null)
            {
                settings.LastTrainingDate = DateTime.UtcNow;
                settings.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }
    }
}

