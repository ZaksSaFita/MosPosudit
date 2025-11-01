using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.Notification;
using MosPosudit.Model.Responses.Notification;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class NotificationService : BaseCrudService<NotificationResponse, NotificationSearchObject, Notification, NotificationInsertRequest, NotificationUpdateRequest>, INotificationService
    {
        public NotificationService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Notification> ApplyFilter(IQueryable<Notification> query, NotificationSearchObject search)
        {
            if (search.UserId.HasValue)
                query = query.Where(n => n.UserId == search.UserId.Value);

            if (!string.IsNullOrWhiteSpace(search.Type))
                query = query.Where(n => n.Type == search.Type);

            if (search.IsRead.HasValue)
                query = query.Where(n => n.IsRead == search.IsRead.Value);

            return query.OrderByDescending(n => n.CreatedAt);
        }

        public override async Task<NotificationResponse> CreateAsync(NotificationInsertRequest request)
        {
            var entity = _mapper.Map<Notification>(request);
            entity.CreatedAt = DateTime.UtcNow;
            entity.IsRead = false;

            await _context.Set<Notification>().AddAsync(entity);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(entity.Id) ?? throw new Exception("Failed to retrieve created notification");
        }

        public override async Task<NotificationResponse?> UpdateAsync(int id, NotificationUpdateRequest request)
        {
            var entity = await _context.Set<Notification>().FindAsync(id);
            if (entity == null)
                return null;

            if (request.IsRead.HasValue)
                entity.IsRead = request.IsRead.Value;

            await _context.SaveChangesAsync();
            return await GetByIdAsync(entity.Id);
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
                throw new NotFoundException("Notification not found");

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

    }
}

