using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;
using MailKit.Net.Smtp;

namespace MosPosudit.Worker.Services
{
    // Service for sending emails via SMTP
    public class EmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // Sends an email to the specified recipient
        public void SendEmail(string recipientEmail, string subject, string body, bool isHtml = true)
        {
            var smtpHost = _configuration["SMTP:Host"] ?? Environment.GetEnvironmentVariable("SMTP_HOST");
            var smtpPortString = _configuration["SMTP:Port"] ?? Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587";
            var smtpPort = int.Parse(smtpPortString);
            var smtpUsername = _configuration["SMTP:Username"] ?? Environment.GetEnvironmentVariable("SMTP_USERNAME");
            var smtpPassword = _configuration["SMTP:Password"] ?? Environment.GetEnvironmentVariable("SMTP_PASSWORD");
            var enableSslString = _configuration["SMTP:EnableSsl"] ?? Environment.GetEnvironmentVariable("SMTP_ENABLE_SSL");
            var enableSsl = smtpPort == 587 || (enableSslString != null && bool.Parse(enableSslString));

            if (string.IsNullOrEmpty(smtpHost) || string.IsNullOrEmpty(smtpUsername) || string.IsNullOrEmpty(smtpPassword))
            {
                _logger.LogWarning("SMTP configuration missing. Email not sent to {Recipient}", recipientEmail);
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
                var sslOption = enableSsl 
                    ? MailKit.Security.SecureSocketOptions.StartTls 
                    : MailKit.Security.SecureSocketOptions.None;
                
                client.Connect(smtpHost, smtpPort, sslOption);
                client.Authenticate(smtpUsername, smtpPassword);
                client.Send(emailMessage);
                _logger.LogInformation("Email sent to {Recipient}: {Subject}", recipientEmail, subject);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending email to {Recipient}", recipientEmail);
                throw;
            }
            finally
            {
                try { client.Disconnect(true); } catch { }
            }
        }
    }
}

