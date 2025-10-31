using MosPosudit.Model.Requests.Message;
using MosPosudit.Model.Responses.Message;

namespace MosPosudit.Services.Interfaces
{
    public interface IChatService
    {
        Task<IEnumerable<MessageResponse>> GetUserMessages(int userId);
        Task<IEnumerable<MessageResponse>> GetPendingMessages();
        Task<MessageResponse> SendMessage(int userId, MessageSendRequest request);
        Task<MessageResponse> SendReply(int fromUserId, int toUserId, MessageSendRequest request);
        Task StartChat(int messageId, int adminId);
        Task MarkAsRead(int messageId, int userId);
    }
}

