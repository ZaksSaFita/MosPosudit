namespace MosPosudit.Services.Interfaces
{
    public interface IMessageService
    {
        void PublishNotification(int userId, string title, string message, string type = "Info");
        void PublishEmail(string to, string subject, string body, bool isHtml = true);
    }
} 