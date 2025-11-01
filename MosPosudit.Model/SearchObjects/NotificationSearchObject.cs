namespace MosPosudit.Model.SearchObjects
{
    public class NotificationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? Type { get; set; }
        public bool? IsRead { get; set; }
    }
}

