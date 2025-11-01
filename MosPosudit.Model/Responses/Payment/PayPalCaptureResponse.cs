namespace MosPosudit.Model.Responses.Payment
{
    public class PayPalCaptureResponse
    {
        public string OrderId { get; set; } = string.Empty; // PayPal Order ID
        public string TransactionId { get; set; } = string.Empty; // PayPal Transaction ID
        public string Status { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public bool IsCompleted { get; set; }
        public int DatabaseOrderId { get; set; } // ID Order entiteta u našoj bazi (kreiran tek nakon payment-a)
        public int DatabasePaymentId { get; set; } // ID Payment entiteta u našoj bazi
    }
}

