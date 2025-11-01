using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class Payment
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Order")]
        public int OrderId { get; set; }
        public Order Order { get; set; } = null!;

        public decimal Amount { get; set; }

        public bool IsCompleted { get; set; }

        public string? TransactionId { get; set; }

        public DateTime PaymentDate { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}

