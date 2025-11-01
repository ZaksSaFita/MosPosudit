namespace MosPosudit.Model.Responses.Payment
{
    public class PaymentResponse
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public decimal Amount { get; set; }
        public bool IsCompleted { get; set; }
        public string? TransactionId { get; set; }
        public DateTime PaymentDate { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

