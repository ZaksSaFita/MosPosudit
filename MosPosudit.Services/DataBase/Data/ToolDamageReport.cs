using MosPosudit.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class ToolDamageReport
    {
        [Key]
        public int Id { get; set; }

        public int ToolId { get; set; }

        public int RentalId { get; set; }

        public int ReportedById { get; set; }

        public DateTime DamageDate { get; set; }

        public string? DamageDescription { get; set; }

        public int SeverityLevel { get; set; }

        public decimal? RepairCost { get; set; }

        public int RepairStatusId { get; set; }

        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
        [ForeignKey("RentalId")]
        public Rental Rental { get; set; }
        [ForeignKey("ReportedById")]
        public User ReportedBy { get; set; }
        [ForeignKey("RepairStatusId")]
        public RepairStatus RepairStatus { get; set; }
    }
}
