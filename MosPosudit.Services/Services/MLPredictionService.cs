using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.ML;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Services
{
    // Service for making predictions using pre-trained ML models (cached in memory)
    public class MLPredictionService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<MLPredictionService> _logger;
        private ITransformer? _model;
        private PredictionEngine<ToolRating, ToolRatingPrediction>? _predictionEngine;
        private DateTime? _modelLoadedAt;
        private readonly object _modelLock = new object();

        public MLPredictionService(
            IServiceProvider serviceProvider,
            ILogger<MLPredictionService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        // Gets ML-based recommendations for a user by predicting scores for all available tools
        public async Task<List<int>> GetMLRecommendationsAsync(int userId, int count = 6)
        {
            try
            {
                // Ensure model is loaded
                await EnsureModelLoadedAsync();

                if (_predictionEngine == null)
                {
                    _logger.LogWarning("ML model not available for predictions");
                    return new List<int>();
                }

                using var scope = _serviceProvider.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                // Get all available tools
                var availableTools = await context.Set<Tool>()
                    .Where(t => t.IsAvailable && t.Quantity > 0)
                    .Select(t => t.Id)
                    .ToListAsync();

                // Get tools user has already ordered (to exclude them)
                var userOrderedToolIds = await context.Set<Order>()
                    .Where(o => o.UserId == userId)
                    .SelectMany(o => o.OrderItems)
                    .Select(oi => oi.ToolId)
                    .Distinct()
                    .ToListAsync();

                // Predict scores for all available tools the user hasn't ordered
                var predictions = new List<(int ToolId, float Score)>();

                foreach (var toolId in availableTools.Where(id => !userOrderedToolIds.Contains(id)))
                {
                    var input = new ToolRating
                    {
                        UserId = userId,
                        ToolId = toolId
                    };

                    var prediction = _predictionEngine.Predict(input);
                    predictions.Add((toolId, prediction.Score));
                }

                // Return top N tools by predicted score
                var recommendations = predictions
                    .OrderByDescending(p => p.Score)
                    .Take(count)
                    .Select(p => p.ToolId)
                    .ToList();

                _logger.LogInformation("Generated {Count} ML recommendations for user {UserId}", recommendations.Count, userId);
                return recommendations;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating ML recommendations for user {UserId}", userId);
                return new List<int>();
            }
        }

        // Gets ML-based cart recommendations by predicting what users who rented this tool would like
        public async Task<List<int>> GetMLCartRecommendationsAsync(int toolId, int count = 3)
        {
            try
            {
                await EnsureModelLoadedAsync();

                if (_predictionEngine == null)
                {
                    _logger.LogWarning("ML model not available for cart predictions");
                    return new List<int>();
                }

                using var scope = _serviceProvider.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                // Find users who rented this tool
                var userIds = await context.Set<Order>()
                    .Where(o => o.OrderItems.Any(oi => oi.ToolId == toolId))
                    .Select(o => o.UserId)
                    .Distinct()
                    .ToListAsync();

                if (!userIds.Any())
                    return new List<int>();

                // Get available tools (excluding the current one)
                var availableTools = await context.Set<Tool>()
                    .Where(t => t.IsAvailable && t.Quantity > 0 && t.Id != toolId)
                    .Select(t => t.Id)
                    .ToListAsync();

                // Predict scores for each available tool across all users who rented the target tool
                var toolScores = new Dictionary<int, float>();

                foreach (var otherToolId in availableTools)
                {
                    float totalScore = 0;
                    foreach (var userId in userIds)
                    {
                        var input = new ToolRating
                        {
                            UserId = userId,
                            ToolId = otherToolId
                        };

                        var prediction = _predictionEngine.Predict(input);
                        totalScore += prediction.Score;
                    }

                    toolScores[otherToolId] = totalScore / userIds.Count;
                }

                // Return top N tools by average predicted score
                var recommendations = toolScores
                    .OrderByDescending(kvp => kvp.Value)
                    .Take(count)
                    .Select(kvp => kvp.Key)
                    .ToList();

                _logger.LogInformation("Generated {Count} ML cart recommendations for tool {ToolId}", recommendations.Count, toolId);
                return recommendations;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating ML cart recommendations for tool {ToolId}", toolId);
                return new List<int>();
            }
        }

        // Ensures the latest ML model is loaded in memory
        private async Task EnsureModelLoadedAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            // Check if model needs to be loaded or refreshed
            var activeModel = await context.MLRecommendationModels
                .Where(m => m.IsActive)
                .OrderByDescending(m => m.TrainedAt)
                .FirstOrDefaultAsync();

            if (activeModel == null)
            {
                _logger.LogWarning("No active ML model found in database");
                return;
            }

            // Check if we need to reload the model
            lock (_modelLock)
            {
                if (_model != null && _modelLoadedAt.HasValue && _modelLoadedAt.Value >= activeModel.TrainedAt)
                {
                    // Model is already loaded and up to date
                    return;
                }
            }

            // Load the model
            await LoadModelAsync(activeModel.ModelFilePath);
        }

        // Loads a model from disk and creates prediction engine
        private async Task LoadModelAsync(string modelPath)
        {
            await Task.Run(() =>
            {
                try
                {
                    if (!File.Exists(modelPath))
                    {
                        _logger.LogError("Model file not found: {Path}", modelPath);
                        return;
                    }

                    _logger.LogInformation("Loading ML model from: {Path}", modelPath);

                    var mlContext = new MLContext();
                    
                    lock (_modelLock)
                    {
                        _model = mlContext.Model.Load(modelPath, out var schema);
                        _predictionEngine = mlContext.Model.CreatePredictionEngine<ToolRating, ToolRatingPrediction>(_model);
                        _modelLoadedAt = DateTime.UtcNow;
                    }

                    _logger.LogInformation("ML model loaded successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error loading ML model from {Path}", modelPath);
                }
            });
        }

        // Checks if ML model is available and ready for predictions
        public bool IsModelAvailable()
        {
            lock (_modelLock)
            {
                return _predictionEngine != null;
            }
        }
    }
}

