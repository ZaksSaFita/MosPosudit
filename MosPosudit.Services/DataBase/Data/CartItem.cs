using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class CartItem
    {
        [Key]
        public int Id { get; set; }

        public int CartId { get; set; }

        public int ToolId { get; set; }

        public int Quantity { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime EndDate { get; set; }

        public decimal DailyRate { get; set; }

        public string? Notes { get; set; }

        // Navigation properties
        [ForeignKey("CartId")]
        public Cart Cart { get; set; }
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
    }
} 
