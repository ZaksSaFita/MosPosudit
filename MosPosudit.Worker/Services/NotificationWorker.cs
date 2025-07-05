using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MosPosudit.Model.Enums;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Worker.Services
{
    public class NotificationWorker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<NotificationWorker> _logger;
        private readonly RabbitMQService _rabbitMQService;

        public NotificationWorker(
            IServiceProvider serviceProvider,
            ILogger<NotificationWorker> logger,
            RabbitMQService rabbitMQService)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _rabbitMQService = rabbitMQService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Notification Worker started");

            // Subscribe to notification queue
            _rabbitMQService.SubscribeToQueue<NotificationMessage>("notifications", HandleNotification);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Check for overdue rentals and send reminders
                    await CheckOverdueRentals();

                    // Wait for 1 hour before next check
                    await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in notification worker");
                    await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
                }
            }
        }

        private void HandleNotification(NotificationMessage message)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                var notification = new Notification
                {
                    UserId = message.UserId,
                    Title = message.Title,
                    Message = message.Message,
                    Type = message.Type,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                };

                context.Notifications.Add(notification);
                _ = context.SaveChangesAsync();

                _logger.LogInformation($"Notification created for user {message.UserId}: {message.Title}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling notification");
            }
        }

        private async Task CheckOverdueRentals()
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                var overdueRentals = await context.Rentals
                    .Include(r => r.User)
                    .Include(r => r.RentalItems)
                    .ThenInclude(ri => ri.Tool)
                    .Where(r => r.EndDate < DateTime.UtcNow && r.Status == RentalStatus.Active)
                    .ToListAsync();

                foreach (var rental in overdueRentals)
                {
                    var message = new NotificationMessage
                    {
                        UserId = rental.UserId,
                        Title = "Overdue Rental",
                        Message = $"Your rental for {string.Join(", ", rental.RentalItems.Select(ri => ri.Tool.Name))} is overdue. Please return the items.",
                        Type = "Warning"
                    };

                    _rabbitMQService.PublishMessage("notifications", message);
                }

                _logger.LogInformation($"Checked {overdueRentals.Count} overdue rentals");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking overdue rentals");
            }
        }
    }

    public class NotificationMessage
    {
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
    }
}