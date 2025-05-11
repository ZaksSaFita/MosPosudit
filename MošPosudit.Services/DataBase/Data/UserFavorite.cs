using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Services.DataBase.Data
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

        // Navigation properties
        public User User { get; set; }
        public Tool Tool { get; set; }
    }
} 