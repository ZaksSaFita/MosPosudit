using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class PaymentTransaction
    {
        [Key]
        public int Id { get; set; }

        public int RentalId { get; set; }

        public int PaymentMethodId { get; set; }

        public int StatusId { get; set; }

        public decimal Amount { get; set; }

        public DateTime TransactionDate { get; set; }

        public string? TransactionReference { get; set; }

        public string? Notes { get; set; }

        public string? TransactionId { get; set; }

        public string? PaymentReference { get; set; }

        public string? RefundReason { get; set; }

        public int UserId { get; set; }

        public int OrderId { get; set; }

        // Navigation properties
        [ForeignKey("RentalId")]
        public Rental Rental { get; set; }

        [ForeignKey("PaymentMethodId")]
        public PaymentMethod PaymentMethod { get; set; }

        [ForeignKey("StatusId")]
        public PaymentStatus Status { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; }

        [ForeignKey("OrderId")]
        public Order Order { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public DateTime? RefundedAt { get; set; }

        public string? Description { get; set; }
    }
}
