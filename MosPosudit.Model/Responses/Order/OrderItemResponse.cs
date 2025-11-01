namespace MosPosudit.Model.Responses.Order
{
    public class OrderItemResponse
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int ToolId { get; set; }
        public string? ToolName { get; set; }
        public int Quantity { get; set; }
        public decimal DailyRate { get; set; }
        public decimal TotalPrice { get; set; }
    }
}

