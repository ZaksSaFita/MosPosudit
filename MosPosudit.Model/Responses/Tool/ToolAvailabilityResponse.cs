namespace MosPosudit.Model.Responses.Tool
{
    public class ToolAvailabilityResponse
    {
        public int ToolId { get; set; }
        public int TotalQuantity { get; set; }
        public Dictionary<string, int> DailyAvailability { get; set; } = new Dictionary<string, int>();
    }
}

