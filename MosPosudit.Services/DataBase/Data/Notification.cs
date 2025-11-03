using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        public string? Title { get; set; }

        public string? Message { get; set; }

        public string? Type { get; set; }

        public bool IsRead { get; set; }

        public DateTime CreatedAt { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
    }
} 
