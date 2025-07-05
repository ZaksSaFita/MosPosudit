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
        private readonly IConnection _connection;
        private readonly IModel _channel;
        private readonly ILogger<MessageService> _logger;

        public MessageService(IConfiguration configuration, ILogger<MessageService> logger)
        {
            _logger = logger;

            var factory = new ConnectionFactory
            {
                HostName = configuration["RabbitMQ:Host"],
                UserName = configuration["RabbitMQ:Username"],
                Password = configuration["RabbitMQ:Password"]
            };

            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();

            // Declare queues
            _channel.QueueDeclare("notifications", durable: true, exclusive: false, autoDelete: false);
            _channel.QueueDeclare("emails", durable: true, exclusive: false, autoDelete: false);
            _channel.QueueDeclare("rental_reminders", durable: true, exclusive: false, autoDelete: false);
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

        public void PublishRentalReminder(int userId, string message)
        {
            var reminderMessage = new
            {
                UserId = userId,
                Message = message,
                Timestamp = DateTime.UtcNow
            };

            PublishMessage("rental_reminders", reminderMessage);
        }

        private void PublishMessage<T>(string queueName, T message)
        {
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
            }
        }

        public void Dispose()
        {
            _channel?.Dispose();
            _connection?.Dispose();
        }
    }
}