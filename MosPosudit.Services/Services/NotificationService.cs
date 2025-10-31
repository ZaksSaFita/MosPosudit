using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Responses.Notification;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly ApplicationDbContext _context;

        public NotificationService(ApplicationDbContext context)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
        }

        public async Task<IEnumerable<NotificationResponse>> GetNotificationsForUser(int userId, int? limit = null)
        {
            var query = _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .AsQueryable();

            if (limit.HasValue && limit.Value > 0)
            {
                query = query.Take(limit.Value);
            }

            var notifications = await query.ToListAsync();
            return notifications.Select(MapToResponse);
        }

        public async Task<int> GetUnreadCountForUser(int userId)
        {
            return await _context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead);
        }

        public async Task MarkAsRead(int notificationId, int userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

            if (notification == null)
                throw new Model.Exceptions.NotFoundException("Notification not found");

            notification.IsRead = true;
            await _context.SaveChangesAsync();
        }

        public async Task MarkAllAsRead(int userId)
        {
            var unreadNotifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var notification in unreadNotifications)
            {
                notification.IsRead = true;
            }

            await _context.SaveChangesAsync();
        }

        public async Task<bool> DeleteNotification(int notificationId, int userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

            if (notification == null)
                return false;

            _context.Notifications.Remove(notification);
            await _context.SaveChangesAsync();
            return true;
        }

        private NotificationResponse MapToResponse(Notification entity)
        {
            return new NotificationResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                Title = entity.Title,
                Message = entity.Message,
                Type = entity.Type,
                IsRead = entity.IsRead,
                CreatedAt = entity.CreatedAt
            };
        }
    }
}

