using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class PaymentTransaction
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int RentalId { get; set; }

        [Required]
        public int PaymentMethodId { get; set; }

        [Required]
        public int StatusId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal Amount { get; set; }

        [Required]
        public DateTime TransactionDate { get; set; }

        [MaxLength(100)]
        public string? TransactionReference { get; set; }

        [MaxLength(500)]
        public string? Notes { get; set; }

        [MaxLength(100)]
        public string? TransactionId { get; set; }

        [MaxLength(100)]
        public string? PaymentReference { get; set; }

        [MaxLength(100)]
        public string? RefundReason { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
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

        [Required]
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public DateTime? RefundedAt { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }
    }
}
