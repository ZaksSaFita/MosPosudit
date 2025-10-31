using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Services.DataBase.Data
{
    public class PaymentMethod
    {
        [Key]
        public int Id { get; set; }

        public string Name { get; set; }

        public string? Description { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
} 
