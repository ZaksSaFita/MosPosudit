using MošPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class Order
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public DateTime OrderDate { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        [Required]
        public decimal TotalAmount { get; set; }

        [Required]
        public int StatusId { get; set; }

        [Required]
        public int PaymentMethodId { get; set; }

        public string? OrderNumber { get; set; }
        public string? Notes { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public User User { get; set; }
        [ForeignKey("StatusId")]
        public OrderStatus Status { get; set; }
        [ForeignKey("PaymentMethodId")]
        public PaymentMethod PaymentMethod { get; set; }
        public ICollection<OrderItem> OrderItems { get; set; }
        public ICollection<PaymentTransaction> Payments { get; set; }

        // Logging properties
        [NotMapped]
        public string EntityName => "Order";

        [NotMapped]
        public string DisplayName => $"Order #{Id} - {User?.Username}";
    }
}