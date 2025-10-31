namespace MosPosudit.Model.Requests.Tool
{
    public class ToolPatchRequest
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public int? CategoryId { get; set; }
        public decimal? DailyRate { get; set; }
        public int? Quantity { get; set; }
        public decimal? DepositAmount { get; set; }
        public bool? IsAvailable { get; set; }
        public string? ImageBase64 { get; set; }
    }
}

