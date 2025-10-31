namespace MosPosudit.Model.Responses.UserFavorite
{
    public class UserFavoriteResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ToolId { get; set; }
        public string? ToolName { get; set; }
        public string? ToolDescription { get; set; }
        public decimal? ToolDailyRate { get; set; }
        public string? ToolImageBase64 { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

