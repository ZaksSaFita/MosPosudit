using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class PaymentTransaction
    {
        [Key]
        public int Id { get; set; }

        public int RentalId { get; set; }

        public string PaymentMethod { get; set; } = string.Empty; // Only PayPal is supported

        public string Status { get; set; } = string.Empty; // Pending, Completed, Cancelled, Refunded

        // Terms of Service acceptance (tracked at payment time)
        public bool TermsAccepted { get; set; }
        public DateTime? TermsAcceptedAt { get; set; }

        public decimal Amount { get; set; }

        public DateTime TransactionDate { get; set; }

        public string? TransactionId { get; set; } // PayPal order ID

        public int UserId { get; set; }

        // Navigation properties
        [ForeignKey("RentalId")]
        public Rental Rental { get; set; } = null!;

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;

        public DateTime CreatedAt { get; set; }
        public DateTime? ProcessedAt { get; set; }
    }
}
