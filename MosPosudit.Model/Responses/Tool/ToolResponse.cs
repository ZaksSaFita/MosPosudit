namespace MosPosudit.Model.Responses.Tool
{
    public class ToolResponse
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Description { get; set; }
        public int CategoryId { get; set; }
        public string? CategoryName { get; set; }
        public decimal DailyRate { get; set; }
        public int Quantity { get; set; }
        public bool IsAvailable { get; set; }
        public decimal DepositAmount { get; set; }
        public string? ImageBase64 { get; set; }
        public double? AverageRating { get; set; } // Average rating from reviews, null if no reviews (defaults to 5.0 on frontend)
    }
}

