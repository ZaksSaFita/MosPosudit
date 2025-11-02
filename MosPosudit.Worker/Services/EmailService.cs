using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;
using MailKit.Net.Smtp;

namespace MosPosudit.Worker.Services
{
    public class EmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public void SendEmail(string recipientEmail, string subject, string body, bool isHtml = true)
        {
            var smtpHost = _configuration["SMTP:Host"] ?? Environment.GetEnvironmentVariable("SMTP_HOST");
            var smtpPortString = _configuration["SMTP:Port"] ?? Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587";
            var smtpPort = int.Parse(smtpPortString);
            var smtpUsername = _configuration["SMTP:Username"] ?? Environment.GetEnvironmentVariable("SMTP_USERNAME");
            var smtpPassword = _configuration["SMTP:Password"] ?? Environment.GetEnvironmentVariable("SMTP_PASSWORD");
            
            // Read EnableSsl setting (default to true for port 587, false for port 25)
            var enableSslString = _configuration["SMTP:EnableSsl"] ?? Environment.GetEnvironmentVariable("SMTP_ENABLE_SSL");
            var enableSsl = smtpPort == 587 || (enableSslString != null && bool.Parse(enableSslString));

            if (string.IsNullOrEmpty(smtpHost) || string.IsNullOrEmpty(smtpUsername) || string.IsNullOrEmpty(smtpPassword))
            {
                _logger.LogWarning($"SMTP configuration is missing. Host: {smtpHost ?? "null"}, Username: {smtpUsername ?? "null"}, Password: {(string.IsNullOrEmpty(smtpPassword) ? "null" : "***")}");
                _logger.LogWarning($"Email will not be sent to {recipientEmail}");
                return;
            }

            var emailMessage = new MimeMessage();
            emailMessage.From.Add(new MailboxAddress("MošPosudit", smtpUsername));
            emailMessage.To.Add(new MailboxAddress("Customer", recipientEmail));
            emailMessage.Subject = subject;

            emailMessage.Body = isHtml 
                ? new TextPart("html") { Text = body }
                : new TextPart("plain") { Text = body };

            using var client = new SmtpClient();
            try
            {
                _logger.LogInformation($"EmailService: Connecting to SMTP server {smtpHost}:{smtpPort}, SSL: {enableSsl}");
                
                // Use appropriate SSL option based on configuration
                var sslOption = enableSsl 
                    ? MailKit.Security.SecureSocketOptions.StartTls 
                    : MailKit.Security.SecureSocketOptions.None;
                
                client.Connect(smtpHost, smtpPort, sslOption);
                _logger.LogInformation($"EmailService: Authenticating with username {smtpUsername}");
                client.Authenticate(smtpUsername, smtpPassword);
                _logger.LogInformation($"EmailService: Sending email to {recipientEmail}");
                client.Send(emailMessage);
                _logger.LogInformation($"Email sent successfully to {recipientEmail}: {subject}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"An error occurred while sending email to {recipientEmail}: {ex.Message}");
                throw; // Re-throw to let EmailConsumer handle it
            }
            finally
            {
                try
                {
                    client.Disconnect(true);
                }
                catch { }
            }
        }
    }
}

