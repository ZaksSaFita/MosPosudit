namespace MosPosudit.Model.SearchObjects
{
    public class MessageSearchObject : BaseSearchObject
    {
        public int? FromUserId { get; set; }
        public int? ToUserId { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsRead { get; set; }
        public int? StartedByAdminId { get; set; }
    }
}

