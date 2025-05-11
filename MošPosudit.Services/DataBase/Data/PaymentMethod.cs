using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Services.DataBase.Data
{
    public class PaymentMethod
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; }

        [MaxLength(200)]
        public string Description { get; set; }

        public bool IsActive { get; set; } = true;

        // Navigation properties
        public ICollection<PaymentTransaction> Transactions { get; set; }
    }
} 