using MošPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class Rental
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        [Required]
        public int StatusId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal TotalPrice { get; set; }

        public DateTime CreatedAt { get; set; }

        [MaxLength(500)]
        public string? Notes { get; set; }

        [Required]
        public int ToolId { get; set; }
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }

        public bool IsReturned { get; set; }
        public DateTime? ReturnDate { get; set; }
        public string? ReturnNotes { get; set; }

        public decimal TotalAmount { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public User User { get; set; }
        [ForeignKey("StatusId")]
        public RentalStatus Status { get; set; }
        public ICollection<RentalItem> RentalItems { get; set; }
        public ICollection<PaymentTransaction> Payments { get; set; }
    }
}