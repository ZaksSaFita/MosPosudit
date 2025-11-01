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
            var smtpHost = _configuration["SMTP:Host"] ?? Environment.GetEnvironmentVariable("SMTP_HOST") ?? throw new InvalidOperationException("SMTP:Host is not configured");
            var smtpPortString = _configuration["SMTP:Port"] ?? Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587";
            var smtpPort = int.Parse(smtpPortString);
            var smtpUsername = _configuration["SMTP:Username"] ?? Environment.GetEnvironmentVariable("SMTP_USERNAME") ?? throw new InvalidOperationException("SMTP:Username is not configured");
            var smtpPassword = _configuration["SMTP:Password"] ?? Environment.GetEnvironmentVariable("SMTP_PASSWORD") ?? throw new InvalidOperationException("SMTP:Password is not configured");

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
                client.Connect(smtpHost, smtpPort, false);
                client.Authenticate(smtpUsername, smtpPassword);
                client.Send(emailMessage);
                _logger.LogInformation($"Email sent successfully to {recipientEmail}: {subject}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"An error occurred while sending email to {recipientEmail}: {ex.Message}");
            }
            finally
            {
                client.Disconnect(true);
                client.Dispose();
            }
        }
    }
}

