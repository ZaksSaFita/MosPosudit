using MosPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class ToolMaintenanceSchedule
    {
        [Key]
        public int Id { get; set; }

        public int ToolId { get; set; }

        public DateTime PlannedDate { get; set; }

        public int MaintenanceTypeId { get; set; }

        public int? AssignedToId { get; set; }

        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
        [ForeignKey("MaintenanceTypeId")]
        public MaintenanceType MaintenanceType { get; set; }
        [ForeignKey("AssignedToId")]
        public User AssignedTo { get; set; }
    }
}
