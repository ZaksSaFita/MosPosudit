using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class Tool
    {
        [Key]
        public int Id { get; set; }

        public string? Name { get; set; }

        public string? Description { get; set; }

        public int CategoryId { get; set; }

        public decimal DailyRate { get; set; }

        public int Quantity { get; set; }

        public DateTime CreatedAt { get; set; }

        public bool IsAvailable { get; set; }

        public decimal DepositAmount { get; set; }
        
        public DateTime? LastMaintenanceDate { get; set; }
        
        public DateTime? NextMaintenanceDate { get; set; }

        // Image stored as base64 (null for seeded data - Flutter will load from assets based on name)
        public string? ImageBase64 { get; set; }

        // Navigation properties
        [ForeignKey("CategoryId")]
        public Category Category { get; set; } = null!;
        
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
        
        public ICollection<UserFavorite> Favorites { get; set; } = new List<UserFavorite>();
    }
}
