using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;
using System.Text;

namespace MosPosudit.Worker.Services
{
    public class RabbitMQService : IDisposable
    {
        private readonly IConnection _connection;
        private readonly IModel _channel;
        private readonly ILogger<RabbitMQService> _logger;

        public RabbitMQService(IConfiguration configuration, ILogger<RabbitMQService> logger)
        {
            _logger = logger;

            var factory = new ConnectionFactory
            {
                HostName = configuration["RabbitMQ:Host"],
                UserName = configuration["RabbitMQ:Username"],
                Password = configuration["RabbitMQ:Password"],
                AutomaticRecoveryEnabled = true,
                NetworkRecoveryInterval = TimeSpan.FromSeconds(10)
            };

            // Retry logic for connecting to RabbitMQ
            var maxRetries = 30;
            var retryDelay = TimeSpan.FromSeconds(2);
            IConnection? connection = null;

            for (int i = 0; i < maxRetries; i++)
            {
                try
                {
                    _logger.LogInformation("Attempting to connect to RabbitMQ (attempt {Attempt}/{MaxRetries})...", i + 1, maxRetries);
                    connection = factory.CreateConnection();
                    _logger.LogInformation("Successfully connected to RabbitMQ");
                    break;
                }
                catch (BrokerUnreachableException ex)
                {
                    if (i == maxRetries - 1)
                    {
                        _logger.LogError(ex, "Failed to connect to RabbitMQ after {MaxRetries} attempts", maxRetries);
                        throw;
                    }
                    _logger.LogWarning("RabbitMQ not ready yet, waiting {Delay} seconds before retry...", retryDelay.TotalSeconds);
                    Thread.Sleep(retryDelay);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Unexpected error connecting to RabbitMQ");
                    if (i == maxRetries - 1)
                        throw;
                    Thread.Sleep(retryDelay);
                }
            }

            _connection = connection ?? throw new InvalidOperationException("Failed to establish RabbitMQ connection");
            _channel = _connection.CreateModel();

            // Declare queues
            _channel.QueueDeclare("notifications", durable: true, exclusive: false, autoDelete: false);
            _channel.QueueDeclare("emails", durable: true, exclusive: false, autoDelete: false);
            _channel.QueueDeclare("rental_reminders", durable: true, exclusive: false, autoDelete: false);
            
            _logger.LogInformation("RabbitMQ queues declared successfully");
        }

        public void PublishMessage<T>(string queueName, T message)
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

        public void SubscribeToQueue<T>(string queueName, Action<T> handler)
        {
            var consumer = new EventingBasicConsumer(_channel);

            consumer.Received += (model, ea) =>
            {
                var body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);
                var deserializedMessage = JsonConvert.DeserializeObject<T>(message);

                if (deserializedMessage != null)
                {
                    handler(deserializedMessage);
                }

                _channel.BasicAck(ea.DeliveryTag, false);
            };

            _channel.BasicConsume(queue: queueName, autoAck: false, consumer: consumer);
        }

        public void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
        }
    }
}