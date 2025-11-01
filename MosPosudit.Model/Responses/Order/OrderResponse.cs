using MosPosudit.Model.Responses.Payment;

namespace MosPosudit.Model.Responses.Order
{
    public class OrderResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string? UserFullName { get; set; }
        public string? UserEmail { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal TotalAmount { get; set; }
        public bool TermsAccepted { get; set; }
        public bool ConfirmationEmailSent { get; set; }
        public bool IsReturned { get; set; }
        public DateTime? ReturnDate { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public List<OrderItemResponse> OrderItems { get; set; } = new List<OrderItemResponse>();
        public List<PaymentResponse> Payments { get; set; } = new List<PaymentResponse>();
    }
}

