using MosPosudit.Model.Enums;
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

        public int ConditionId { get; set; }

        public decimal DailyRate { get; set; }

        public int Quantity { get; set; }

        public DateTime CreatedAt { get; set; }

        public bool IsAvailable { get; set; }

        // Add missing properties
        public decimal DepositAmount { get; set; }
        public DateTime? LastMaintenanceDate { get; set; }
        public DateTime? NextMaintenanceDate { get; set; }

        // Image stored as base64 (null for seeded data - Flutter will load from assets based on name)
        public string? ImageBase64 { get; set; }

        // Navigation properties
        [ForeignKey("CategoryId")]
        public Category Category { get; set; }
        public ToolCondition Condition { get; set; }
        public ICollection<RentalItem> RentalItems { get; set; }
        public ICollection<Review> Reviews { get; set; }
        public ICollection<CartItem> CartItems { get; set; }
        public ICollection<OrderItem> OrderItems { get; set; }
        public ICollection<UserFavorite> Favorites { get; set; }
        public ICollection<ToolDamageReport> DamageReports { get; set; }
        public ICollection<MaintenanceLog> MaintenanceLogs { get; set; }
        public ICollection<ToolMaintenanceSchedule> MaintenanceSchedules { get; set; }
        public ICollection<ToolImage> Images { get; set; }
    }
}
