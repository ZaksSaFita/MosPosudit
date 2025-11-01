using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using Newtonsoft.Json;

namespace MosPosudit.Worker.Services
{
    public class NotificationWorker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<NotificationWorker> _logger;
        private readonly IConfiguration _configuration;
        private readonly IConnection? _connection;
        private readonly IModel? _channel;
        private readonly string _host;
        private readonly string _username;
        private readonly string _password;

        public NotificationWorker(
            IServiceProvider serviceProvider,
            ILogger<NotificationWorker> logger,
            IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _configuration = configuration;

            _host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? _configuration["RabbitMQ:Host"] ?? "localhost";
            _username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? _configuration["RabbitMQ:Username"] ?? "admin";
            _password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? _configuration["RabbitMQ:Password"] ?? "admin123";

            try
            {
                var factory = new ConnectionFactory
                {
                    HostName = _host,
                    UserName = _username,
                    Password = _password,
                    AutomaticRecoveryEnabled = true,
                    NetworkRecoveryInterval = TimeSpan.FromSeconds(10)
                };

                // Retry logic for connecting to RabbitMQ
                var maxRetries = 3;
                var retryDelay = TimeSpan.FromSeconds(1);
                IConnection? connection = null;

                for (int i = 0; i < maxRetries; i++)
                {
                    try
                    {
                        _logger.LogInformation("NotificationWorker: Attempting to connect to RabbitMQ (attempt {Attempt}/{MaxRetries})...", i + 1, maxRetries);
                        connection = factory.CreateConnection();
                        _logger.LogInformation("NotificationWorker: Successfully connected to RabbitMQ");
                        break;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "NotificationWorker: Failed to connect to RabbitMQ on attempt {Attempt}/{MaxRetries}", i + 1, maxRetries);
                        if (i < maxRetries - 1)
                        {
                            Thread.Sleep(retryDelay);
                        }
                    }
                }

                if (connection == null || !connection.IsOpen)
                {
                    _logger.LogWarning("NotificationWorker: RabbitMQ is not available. Notification Worker will not process messages.");
                    _connection = null;
                    _channel = null;
                    return;
                }

                _connection = connection;
                _channel = _connection.CreateModel();

                // Declare queue
                _channel.QueueDeclare(
                    queue: "notifications",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                _logger.LogInformation("NotificationWorker: Queue 'notifications' declared successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "NotificationWorker: Error initializing RabbitMQ connection");
                _connection = null;
                _channel = null;
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Notification Worker started");

            if (_connection == null || _channel == null)
            {
                _logger.LogWarning("NotificationWorker: RabbitMQ is not available. Notification Worker will not process messages.");
                while (!stoppingToken.IsCancellationRequested)
                {
                    await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
                }
                return;
            }

            var consumer = new EventingBasicConsumer(_channel);
            consumer.Received += (model, ea) =>
            {
                try
                {
                    var body = ea.Body.ToArray();
                    var message = Encoding.UTF8.GetString(body);
                    _logger.LogInformation("NotificationWorker: Received message: {Message}", message);

                    var notificationMessage = JsonConvert.DeserializeObject<NotificationMessage>(message);
                    if (notificationMessage != null)
                    {
                        HandleNotification(notificationMessage);
                    }
                    else
                    {
                        _logger.LogWarning("NotificationWorker: Invalid notification message received");
                    }

                    _channel.BasicAck(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "NotificationWorker: Error processing notification message");
                    _channel.BasicNack(ea.DeliveryTag, false, true);
                }
            };

            _channel.BasicConsume(
                queue: "notifications",
                autoAck: false,
                consumer: consumer);

            _logger.LogInformation("NotificationWorker: Subscribed to 'notifications' queue");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
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
                context.SaveChanges();

                _logger.LogInformation("NotificationWorker: Notification created for user {UserId}: {Title}", message.UserId, message.Title);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "NotificationWorker: Error handling notification");
            }
        }

        public override void Dispose()
        {
            try
            {
                _channel?.Close();
                _channel?.Dispose();
            }
            catch { }

            try
            {
                _connection?.Close();
                _connection?.Dispose();
            }
            catch { }

            base.Dispose();
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