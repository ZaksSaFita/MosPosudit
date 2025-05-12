using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class RentalItem
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int RentalId { get; set; }

        [Required]
        public int ToolId { get; set; }

        [Required]
        [Range(1, int.MaxValue)]
        public int Quantity { get; set; }

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal DailyRate { get; set; }

        public string? Notes { get; set; }

        // Navigation properties
        [ForeignKey("RentalId")]
        public Rental Rental { get; set; }
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
    }
} 