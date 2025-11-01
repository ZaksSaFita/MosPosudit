namespace MosPosudit.Model.Requests.Message
{
    public class MessageUpdateRequest
    {
        public bool? IsRead { get; set; }
        public bool? IsActive { get; set; }
        public int? ToUserId { get; set; }
    }
}

