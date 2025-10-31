using MosPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class MaintenanceLog
    {
        [Key]
        public int Id { get; set; }

        public int ToolId { get; set; }

        public int MaintenanceTypeId { get; set; }

        public DateTime MaintenanceDate { get; set; }

        public string Description { get; set; }

        public decimal Cost { get; set; }

        public string? Notes { get; set; }

        public string? PerformedBy { get; set; }

        public DateTime? NextMaintenanceDate { get; set; }

        // Navigation properties
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
        [ForeignKey("MaintenanceTypeId")]
        public MaintenanceType MaintenanceType { get; set; }
    }
}
