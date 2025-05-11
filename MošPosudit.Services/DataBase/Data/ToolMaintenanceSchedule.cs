using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Services.DataBase.Data
{
    public class ToolMaintenanceSchedule
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ToolId { get; set; }

        [Required]
        public DateTime PlannedDate { get; set; }

        [Required]
        public int MaintenanceTypeId { get; set; }

        public int? AssignedToId { get; set; }

        [MaxLength(500)]
        public string Notes { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        public Tool Tool { get; set; }
        public MaintenanceType MaintenanceType { get; set; }
        public User AssignedTo { get; set; }
    }
} 