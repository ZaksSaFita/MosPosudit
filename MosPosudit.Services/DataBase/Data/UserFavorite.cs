using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class UserFavorite
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public int ToolId { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        public string? Notes { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public User User { get; set; }
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
    }
} 
