using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class ToolDamageReport
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ToolId { get; set; }

        [Required]
        public int RentalId { get; set; }

        [Required]
        public int ReportedById { get; set; }

        [Required]
        public DateTime DamageDate { get; set; }

        [Required]
        [MaxLength(1000)]
        public string DamageDescription { get; set; }

        [Required]
        [Range(1, 5)]
        public int SeverityLevel { get; set; }

        public decimal? RepairCost { get; set; }

        [Required]
        public int RepairStatusId { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        public Tool Tool { get; set; }
        public Rental Rental { get; set; }
        public User ReportedBy { get; set; }
        public RepairStatus RepairStatus { get; set; }

        // Logging properties
        [NotMapped]
        public string EntityName => "ToolDamageReport";

        [NotMapped]
        public string DisplayName => $"Damage Report for {Tool?.Name} by {ReportedBy?.Username}";
    }
} 