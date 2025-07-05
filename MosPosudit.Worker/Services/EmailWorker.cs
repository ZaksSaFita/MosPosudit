using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Net.Mail;
using Newtonsoft.Json;

namespace MosPosudit.Worker.Services
{
    public class EmailWorker : BackgroundService
    {
        private readonly ILogger<EmailWorker> _logger;
        private readonly RabbitMQService _rabbitMQService;
        private readonly IConfiguration _configuration;

        public EmailWorker(
            ILogger<EmailWorker> logger,
            RabbitMQService rabbitMQService,
            IConfiguration configuration)
        {
            _logger = logger;
            _rabbitMQService = rabbitMQService;
            _configuration = configuration;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Email Worker started");

            // Subscribe to email queue
            _rabbitMQService.SubscribeToQueue<EmailMessage>("emails", HandleEmail);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Check for rental reminders and send emails
                    await Task.Delay(TimeSpan.FromHours(2), stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in email worker");
                    await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
                }
            }
        }

        private void HandleEmail(EmailMessage message)
        {
            try
            {
                _ = SendEmailAsync(message);
                _logger.LogInformation($"Email sent to {message.To}: {message.Subject}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending email");
            }
        }

        private async Task SendEmailAsync(EmailMessage message)
        {
            var smtpHost = _configuration["SMTP:Host"];
            var smtpPort = int.Parse(_configuration["SMTP:Port"]);
            var smtpUsername = _configuration["SMTP:Username"];
            var smtpPassword = _configuration["SMTP:Password"];
            var enableSsl = bool.Parse(_configuration["SMTP:EnableSsl"] ?? "true");

            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                EnableSsl = enableSsl,
                Credentials = new NetworkCredential(smtpUsername, smtpPassword)
            };

            using var mailMessage = new MailMessage
            {
                From = new MailAddress(smtpUsername),
                Subject = message.Subject,
                Body = message.Body,
                IsBodyHtml = message.IsHtml
            };

            mailMessage.To.Add(message.To);

            await client.SendMailAsync(mailMessage);
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