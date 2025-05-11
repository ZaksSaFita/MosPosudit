using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Services.DataBase.Data
{
    public class Cart
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        public DateTime? LastModifiedAt { get; set; }

        // Navigation properties
        public User User { get; set; }
        public ICollection<CartItem> Items { get; set; }
    }
}