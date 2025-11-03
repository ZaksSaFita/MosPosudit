using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class Review
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        public int ToolId { get; set; }

        public int Rating { get; set; }

        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; } = null!;
    }
}

