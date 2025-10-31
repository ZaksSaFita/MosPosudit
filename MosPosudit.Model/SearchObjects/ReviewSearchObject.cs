namespace MosPosudit.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? ToolId { get; set; }
        public int? UserId { get; set; }
        public int? RentalId { get; set; }
        public int? Rating { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
    }
}

