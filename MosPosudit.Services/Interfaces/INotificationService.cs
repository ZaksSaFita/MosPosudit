using MosPosudit.Model.Responses.Notification;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface INotificationService
    {
        Task<IEnumerable<NotificationResponse>> GetNotificationsForUser(int userId, int? limit = null);
        Task<int> GetUnreadCountForUser(int userId);
        Task MarkAsRead(int notificationId, int userId);
        Task MarkAllAsRead(int userId);
        Task<bool> DeleteNotification(int notificationId, int userId);
    }
}

