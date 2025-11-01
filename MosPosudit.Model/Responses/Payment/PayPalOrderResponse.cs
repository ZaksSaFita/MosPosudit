namespace MosPosudit.Model.Responses.Payment
{
    public class PayPalOrderResponse
    {
        public string OrderId { get; set; } = string.Empty; // PayPal Order ID
        public string ApprovalUrl { get; set; } = string.Empty; // URL za redirect na PayPal
        public string Status { get; set; } = string.Empty;
    }
}

