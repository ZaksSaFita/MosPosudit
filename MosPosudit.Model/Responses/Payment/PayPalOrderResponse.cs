namespace MosPosudit.Model.Responses.Payment
{
    public class PayPalOrderResponse
    {
        public string OrderId { get; set; } = string.Empty;
        public string ApprovalUrl { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
    }
}

