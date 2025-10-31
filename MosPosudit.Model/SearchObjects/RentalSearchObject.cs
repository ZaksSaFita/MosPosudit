namespace MosPosudit.Model.SearchObjects
{
    public class RentalSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? ToolId { get; set; }
        public int? StatusId { get; set; }
        public DateTime? StartDateFrom { get; set; }
        public DateTime? StartDateTo { get; set; }
        public DateTime? EndDateFrom { get; set; }
        public DateTime? EndDateTo { get; set; }
        public bool? IsReturned { get; set; }
        public bool? IsActive { get; set; }
    }
}

