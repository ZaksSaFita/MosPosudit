using MošPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class Tool
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string? Name { get; set; }

        [Required]
        [StringLength(1000)]
        public string? Description { get; set; }

        [Required]
        public int CategoryId { get; set; }

        [Required]
        public int ConditionId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal DailyRate { get; set; }

        [Required]
        public int Quantity { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        [Required]
        public bool IsAvailable { get; set; }

        // Add missing properties
        [Required]
        [Range(0, double.MaxValue)]
        public decimal DepositAmount { get; set; }
        public DateTime? LastMaintenanceDate { get; set; }
        public DateTime? NextMaintenanceDate { get; set; }

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

        // Logging properties
        [NotMapped]
        public string EntityName => "Tool";

        [NotMapped]
        public string DisplayName => $"{Name} ({Category?.Name})";
    }
}