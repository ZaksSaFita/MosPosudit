using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace MosPosudit.Worker.Services
{
    // Background service that periodically trains ML models every N days (configurable)
    public class MLTrainingWorker : BackgroundService
    {
        private readonly ILogger<MLTrainingWorker> _logger;
        private readonly IServiceProvider _serviceProvider;
        private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(5); // Check every 5 minutes for training

        public MLTrainingWorker(
            ILogger<MLTrainingWorker> logger,
            IServiceProvider serviceProvider)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ML Training Worker started");

            // Short delay on startup before first check (10 seconds)
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckAndTrainAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in ML Training Worker");
                }

                // Wait before next check
                await Task.Delay(_checkInterval, stoppingToken);
            }

            _logger.LogInformation("ML Training Worker stopped");
        }

        private async Task CheckAndTrainAsync(CancellationToken stoppingToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var trainingService = scope.ServiceProvider.GetRequiredService<MLTrainingService>();

            try
            {
                // Check if training should run
                var shouldTrain = await trainingService.ShouldTrainAsync();

                if (shouldTrain)
                {
                    _logger.LogInformation("ML training is due. Starting training process...");

                    var success = await trainingService.TrainModelAsync();

                    if (success)
                    {
                        await trainingService.UpdateLastTrainingDateAsync();
                        _logger.LogInformation("ML training completed successfully");
                    }
                    else
                    {
                        _logger.LogWarning("ML training did not complete successfully");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking or training ML model");
            }
        }
    }
}

