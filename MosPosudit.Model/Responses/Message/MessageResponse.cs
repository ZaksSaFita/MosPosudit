namespace MosPosudit.Model.Responses.Message
{
    public class MessageResponse
    {
        public int Id { get; set; }
        public int FromUserId { get; set; }
        public string? FromUserName { get; set; }
        public int? ToUserId { get; set; }
        public string? ToUserName { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime SentAt { get; set; }
        public DateTime? ReadAt { get; set; }
        public bool IsRead { get; set; }
        public bool IsActive { get; set; }
        public int? StartedByAdminId { get; set; }
        public string? StartedByAdminName { get; set; }
    }
}

