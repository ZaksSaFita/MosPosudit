using MosPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class Rental
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        public int StatusId { get; set; }

        public decimal TotalAmount { get; set; }

        public DateTime CreatedAt { get; set; }

        public string? Notes { get; set; }

        public bool IsReturned { get; set; }
        public DateTime? ReturnDate { get; set; }
        public string? ReturnNotes { get; set; }

        // Terms of Service acceptance
        public bool TermsAccepted { get; set; }
        public DateTime? TermsAcceptedAt { get; set; }

        // Email confirmation
        public bool ConfirmationEmailSent { get; set; }
        public DateTime? ConfirmationEmailSentAt { get; set; }

        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        [ForeignKey("StatusId")]
        public RentalStatus Status { get; set; }
        public ICollection<RentalItem> RentalItems { get; set; } = new List<RentalItem>();
        public ICollection<PaymentTransaction> Payments { get; set; } = new List<PaymentTransaction>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
    }
}
