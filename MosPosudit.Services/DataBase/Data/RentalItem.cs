using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class RentalItem
    {
        [Key]
        public int Id { get; set; }

        public int RentalId { get; set; }

        public int ToolId { get; set; }

        public int Quantity { get; set; }

        public decimal DailyRate { get; set; }

        public string? Notes { get; set; }

        // Navigation properties
        [ForeignKey("RentalId")]
        public Rental Rental { get; set; } = null!;
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; } = null!;
    }
} 
