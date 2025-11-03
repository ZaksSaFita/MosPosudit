namespace MosPosudit.Model.Responses.Payment
{
    public class PayPalCaptureResponse
    {
        public string OrderId { get; set; } = string.Empty;
        public string TransactionId { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public bool IsCompleted { get; set; }
        public int DatabaseOrderId { get; set; }
        public int DatabasePaymentId { get; set; }
    }
}

