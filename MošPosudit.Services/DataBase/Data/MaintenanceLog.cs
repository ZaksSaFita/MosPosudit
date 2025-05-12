using MošPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class MaintenanceLog
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ToolId { get; set; }

        [Required]
        public int MaintenanceTypeId { get; set; }

        [Required]
        public DateTime MaintenanceDate { get; set; }

        [Required]
        [StringLength(1000)]
        public string Description { get; set; }

        [Required]
        public decimal Cost { get; set; }

        [StringLength(500)]
        public string? Notes { get; set; }

        [MaxLength(100)]
        public string? PerformedBy { get; set; }

        public DateTime? NextMaintenanceDate { get; set; }

        // Navigation properties
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
        [ForeignKey("MaintenanceTypeId")]
        public MaintenanceType MaintenanceType { get; set; }

        // Logging properties
        [NotMapped]
        public string EntityName => "MaintenanceLog";

        [NotMapped]
        public string DisplayName => $"{MaintenanceType} for {Tool?.Name} on {MaintenanceDate:d}";
    }
}