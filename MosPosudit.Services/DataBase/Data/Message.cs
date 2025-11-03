using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class Message
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("FromUser")]
        public int FromUserId { get; set; }
        public User FromUser { get; set; } = null!;

        [ForeignKey("ToUser")]
        public int? ToUserId { get; set; }
        public User? ToUser { get; set; }

        public string Content { get; set; } = string.Empty;

        public DateTime SentAt { get; set; }

        public DateTime? ReadAt { get; set; }

        public bool IsRead { get; set; }

        public bool IsActive { get; set; }

        [ForeignKey("StartedByAdmin")]
        public int? StartedByAdminId { get; set; }
        public User? StartedByAdmin { get; set; }
    }
}

