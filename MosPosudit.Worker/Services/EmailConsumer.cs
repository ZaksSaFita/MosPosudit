using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using Newtonsoft.Json;

namespace MosPosudit.Worker.Services
{
    public class EmailConsumer : BackgroundService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailConsumer> _logger;
        private readonly EmailService _emailService;
        private readonly IConnection? _connection;
        private readonly IModel? _channel;
        private readonly string _host;
        private readonly string _username;
        private readonly string _password;

        public EmailConsumer(
            IConfiguration configuration,
            ILogger<EmailConsumer> logger,
            EmailService emailService)
        {
            _configuration = configuration;
            _logger = logger;
            _emailService = emailService;

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
                        _logger.LogInformation("EmailConsumer: Attempting to connect to RabbitMQ (attempt {Attempt}/{MaxRetries})...", i + 1, maxRetries);
                        connection = factory.CreateConnection();
                        _logger.LogInformation("EmailConsumer: Successfully connected to RabbitMQ");
                        break;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "EmailConsumer: Failed to connect to RabbitMQ on attempt {Attempt}/{MaxRetries}", i + 1, maxRetries);
                        if (i < maxRetries - 1)
                        {
                            Thread.Sleep(retryDelay);
                        }
                    }
                }

                if (connection == null || !connection.IsOpen)
                {
                    _logger.LogWarning("EmailConsumer: RabbitMQ is not available. EmailConsumer will not process messages.");
                    _connection = null;
                    _channel = null;
                    return;
                }

                _connection = connection;
                _channel = _connection.CreateModel();

                // Declare queue
                _channel.QueueDeclare(
                    queue: "emails",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null);

                _logger.LogInformation("EmailConsumer: Queue 'emails' declared successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "EmailConsumer: Error initializing RabbitMQ connection");
                _connection = null;
                _channel = null;
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Email Consumer started");

            if (_connection == null || _channel == null)
            {
                _logger.LogWarning("EmailConsumer: RabbitMQ is not available. Email Consumer will not process messages.");
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
                    _logger.LogInformation("EmailConsumer: Received message: {Message}", message);

                    var emailMessage = JsonConvert.DeserializeObject<EmailMessage>(message);
                    if (emailMessage != null && !string.IsNullOrEmpty(emailMessage.To))
                    {
                        _emailService.SendEmail(
                            emailMessage.To,
                            emailMessage.Subject,
                            emailMessage.Body,
                            emailMessage.IsHtml);
                    }
                    else
                    {
                        _logger.LogWarning("EmailConsumer: Invalid email message received");
                    }

                    _channel.BasicAck(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "EmailConsumer: Error processing email message");
                    _channel.BasicNack(ea.DeliveryTag, false, true);
                }
            };

            _channel.BasicConsume(
                queue: "emails",
                autoAck: false,
                consumer: consumer);

            _logger.LogInformation("EmailConsumer: Subscribed to 'emails' queue");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
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

    public class EmailMessage
    {
        public string To { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public bool IsHtml { get; set; } = true;
    }
}

