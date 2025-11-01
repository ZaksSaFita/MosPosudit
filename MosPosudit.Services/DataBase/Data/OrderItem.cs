using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class OrderItem
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Order")]
        public int OrderId { get; set; }
        public Order Order { get; set; } = null!;

        [ForeignKey("Tool")]
        public int ToolId { get; set; }
        public Tool Tool { get; set; } = null!;

        public int Quantity { get; set; }

        public decimal DailyRate { get; set; }

        public decimal TotalPrice { get; set; }
    }
}

