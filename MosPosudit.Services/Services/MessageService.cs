using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MosPosudit.Services.Interfaces;
using Newtonsoft.Json;
using RabbitMQ.Client;
using System.Text;

namespace MosPosudit.Services.Services
{
    public class MessageService : IMessageService, IDisposable
    {
        private IConnection? _connection;
        private IModel? _channel;
        private readonly ILogger<MessageService> _logger;
        private readonly IConfiguration _configuration;
        private readonly object _lock = new object();
        private bool _isInitialized = false;

        public MessageService(IConfiguration configuration, ILogger<MessageService> logger)
        {
            _logger = logger;
            _configuration = configuration;
            // Lazy initialization - ne konektuje se u konstruktoru
        }

        private bool EnsureConnected()
        {
            if (_isInitialized && _connection?.IsOpen == true && _channel?.IsOpen == true)
                return true;

            lock (_lock)
            {
                if (_isInitialized && _connection?.IsOpen == true && _channel?.IsOpen == true)
                    return true;

                try
                {
                    var factory = new ConnectionFactory
                    {
                        HostName = _configuration["RabbitMQ:Host"] ?? "localhost",
                        UserName = _configuration["RabbitMQ:Username"] ?? "admin",
                        Password = _configuration["RabbitMQ:Password"] ?? "admin123",
                        Port = 5672,
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
                            _logger.LogInformation($"Attempting to connect to RabbitMQ (attempt {i + 1}/{maxRetries})...");
                            connection = factory.CreateConnection();
                            _logger.LogInformation("Successfully connected to RabbitMQ");
                            break;
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, $"Failed to connect to RabbitMQ on attempt {i + 1}/{maxRetries}");
                            if (i < maxRetries - 1)
                            {
                                Thread.Sleep(retryDelay);
                            }
                        }
                    }

                    if (connection == null || !connection.IsOpen)
                    {
                        _logger.LogWarning("RabbitMQ is not available. MessageService will work in degraded mode (no messages will be sent).");
                        _isInitialized = true;
                        return false;
                    }

                    _connection = connection;
                    _channel = _connection.CreateModel();

                    // Declare queues
                    _channel.QueueDeclare("notifications", durable: true, exclusive: false, autoDelete: false);
                    _channel.QueueDeclare("emails", durable: true, exclusive: false, autoDelete: false);

                    _isInitialized = true;
                    return true;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "RabbitMQ is not available. MessageService will work in degraded mode (no messages will be sent).");
                    _isInitialized = true;
                    return false;
                }
            }
        }

        public void PublishNotification(int userId, string title, string message, string type = "Info")
        {
            var notificationMessage = new
            {
                UserId = userId,
                Title = title,
                Message = message,
                Type = type
            };

            PublishMessage("notifications", notificationMessage);
        }

        public void PublishEmail(string to, string subject, string body, bool isHtml = true)
        {
            var emailMessage = new
            {
                To = to,
                Subject = subject,
                Body = body,
                IsHtml = isHtml
            };

            PublishMessage("emails", emailMessage);
        }

        private void PublishMessage<T>(string queueName, T message)
        {
            if (!EnsureConnected() || _channel == null)
            {
                _logger.LogWarning($"RabbitMQ not available. Message not published to queue: {queueName}");
                return;
            }

            try
            {
                var json = JsonConvert.SerializeObject(message);
                var body = Encoding.UTF8.GetBytes(json);

                _channel.BasicPublish(
                    exchange: "",
                    routingKey: queueName,
                    basicProperties: null,
                    body: body);

                _logger.LogInformation($"Message published to queue: {queueName}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error publishing message to queue: {queueName}");
                // Reset connection so it will retry next time
                _isInitialized = false;
                _channel?.Close();
                _connection?.Close();
                _channel = null;
                _connection = null;
            }
        }

        public void Dispose()
        {
            lock (_lock)
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
            }
        }
    }
}