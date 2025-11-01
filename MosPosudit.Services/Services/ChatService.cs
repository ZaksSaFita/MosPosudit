using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Requests.Message;
using MosPosudit.Model.Responses.Message;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class ChatService : IChatService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMessageService _messageService;
        private readonly IMapper _mapper;

        public ChatService(ApplicationDbContext context, IMessageService messageService, IMapper mapper)
        {
            _context = context;
            _messageService = messageService;
            _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
        }

        public async Task<IEnumerable<MessageResponse>> GetUserMessages(int userId)
        {
            var messages = await _context.Messages
                .Include(m => m.FromUser)
                .Include(m => m.ToUser)
                .Include(m => m.StartedByAdmin)
                .Where(m => m.FromUserId == userId || m.ToUserId == userId)
                .OrderBy(m => m.SentAt)
                .ToListAsync();

            return messages.Select(m =>
            {
                var response = _mapper.Map<MessageResponse>(m);
                response.FromUserName = m.FromUser?.FullName ?? "Unknown";
                response.ToUserName = m.ToUser?.FullName;
                response.StartedByAdminName = m.StartedByAdmin?.FullName;
                return response;
            });
        }

        public async Task<IEnumerable<MessageResponse>> GetPendingMessages()
        {
            // Only show messages that were never in an active chat (StartedByAdminId == null)
            // This excludes messages from closed chats
            var messages = await _context.Messages
                .Include(m => m.FromUser)
                .Where(m => !m.IsActive && m.ToUserId == null && m.StartedByAdminId == null)
                .OrderByDescending(m => m.SentAt)
                .ToListAsync();

            return messages.Select(m =>
            {
                var response = _mapper.Map<MessageResponse>(m);
                response.FromUserName = m.FromUser?.FullName ?? "Unknown";
                response.ToUserName = m.ToUser?.FullName;
                response.StartedByAdminName = m.StartedByAdmin?.FullName;
                return response;
            });
        }

        public async Task<MessageResponse> SendMessage(int userId, MessageSendRequest request)
        {
            var fromUser = await _context.Users.FindAsync(userId);
            if (fromUser == null)
                throw new Exception("User not found");

            var message = new Message
            {
                FromUserId = userId,
                FromUser = fromUser,
                ToUserId = null, // Admin will be assigned when they start the chat
                Content = request.Content,
                SentAt = DateTime.UtcNow,
                IsActive = false,
                IsRead = false
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // Reload with navigation properties
            await _context.Entry(message).Reference(m => m.FromUser).LoadAsync();

            // Send notification to admin via RabbitMQ (asynchronous)
            var adminRole = await _context.Roles.FirstOrDefaultAsync(r => r.Name == "Admin");
            if (adminRole != null)
            {
                var admins = await _context.Users
                    .Where(u => u.RoleId == adminRole.Id && u.IsActive)
                    .ToListAsync();

                foreach (var admin in admins)
                {
                    _messageService.PublishNotification(
                        admin.Id,
                        "New Message",
                        $"You have received a new message from a user.",
                        "NewMessage"
                    );
                }
            }

            var response = _mapper.Map<MessageResponse>(message);
            response.FromUserName = message.FromUser?.FullName ?? "Unknown";
            return response;
        }

        public async Task<MessageResponse> SendReply(int fromUserId, int toUserId, MessageSendRequest request)
        {
            // Find active conversation
            var conversation = await _context.Messages
                .Where(m => (m.FromUserId == fromUserId && m.ToUserId == toUserId) ||
                            (m.FromUserId == toUserId && m.ToUserId == fromUserId))
                .Where(m => m.IsActive)
                .FirstOrDefaultAsync();

            if (conversation == null)
                throw new Exception("No active conversation found");

            var fromUser = await _context.Users.FindAsync(fromUserId);
            if (fromUser == null)
                throw new Exception("User not found");

            var message = new Message
            {
                FromUserId = fromUserId,
                FromUser = fromUser,
                ToUserId = toUserId,
                Content = request.Content,
                SentAt = DateTime.UtcNow,
                IsActive = true,
                IsRead = false
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // Reload with navigation properties
            await _context.Entry(message).Reference(m => m.FromUser).LoadAsync();
            await _context.Entry(message).Reference(m => m.ToUser).LoadAsync();

            // Send notification to recipient via RabbitMQ (asynchronous)
            _messageService.PublishNotification(
                toUserId,
                "New Message",
                "You have received a new message.",
                "NewMessage"
            );

            var response = _mapper.Map<MessageResponse>(message);
            response.FromUserName = message.FromUser?.FullName ?? "Unknown";
            response.ToUserName = message.ToUser?.FullName;
            return response;
        }

        public async Task StartChat(int messageId, int adminId)
        {
            var firstMessage = await _context.Messages
                .Include(m => m.FromUser)
                .FirstOrDefaultAsync(m => m.Id == messageId);

            if (firstMessage == null)
                throw new Exception("Message not found");

            if (firstMessage.IsActive)
                throw new Exception("Chat is already active");

            // Mark all messages from this user as active and assign admin
            var userMessages = await _context.Messages
                .Where(m => m.FromUserId == firstMessage.FromUserId && !m.IsActive)
                .ToListAsync();

            foreach (var msg in userMessages)
            {
                msg.IsActive = true;
                msg.ToUserId = adminId;
                msg.StartedByAdminId = adminId;
            }

            await _context.SaveChangesAsync();

            // Send notification to user via RabbitMQ (asynchronous)
            _messageService.PublishNotification(
                firstMessage.FromUserId,
                "Chat Started",
                "An administrator has started chatting with you.",
                "ChatStarted"
            );
        }

        public async Task StartChatWithUser(int adminId, int userId)
        {
            // Check if user exists
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new Exception("User not found");

            // Check if there's already an active chat between admin and user
            var existingActiveChat = await _context.Messages
                .Where(m => ((m.FromUserId == adminId && m.ToUserId == userId) ||
                            (m.FromUserId == userId && m.ToUserId == adminId)) &&
                            m.IsActive)
                .FirstOrDefaultAsync();

            if (existingActiveChat != null)
                throw new Exception("Chat is already active with this user");

            // Create an initial message from admin to start the chat
            var initialMessage = new Message
            {
                FromUserId = adminId,
                ToUserId = userId,
                Content = "Chat started", // Initial message content
                SentAt = DateTime.UtcNow,
                IsActive = true,
                IsRead = false,
                StartedByAdminId = adminId
            };

            _context.Messages.Add(initialMessage);
            await _context.SaveChangesAsync();

            // Send notification to user via RabbitMQ (asynchronous)
            _messageService.PublishNotification(
                userId,
                "Chat Started",
                "An administrator has started chatting with you.",
                "ChatStarted"
            );
        }

        public async Task MarkAsRead(int messageId, int userId)
        {
            var message = await _context.Messages
                .FirstOrDefaultAsync(m => m.Id == messageId && (m.ToUserId == userId || m.FromUserId == userId));

            if (message == null)
                throw new Exception("Message not found");

            if (!message.IsRead)
            {
                message.IsRead = true;
                message.ReadAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }

    }
}

