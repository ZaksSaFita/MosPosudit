using MosPosudit.Model.Requests.Notification;
using MosPosudit.Model.Responses.Notification;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface INotificationService : ICrudService<NotificationResponse, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest>
    {
        Task<int> GetUnreadCountForUser(int userId);
        Task MarkAsRead(int notificationId, int userId);
        Task MarkAllAsRead(int userId);
    }
}

