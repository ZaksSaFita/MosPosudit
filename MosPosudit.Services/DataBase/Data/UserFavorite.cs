using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class UserFavorite
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        public int ToolId { get; set; }

        public DateTime CreatedAt { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; } = null!;
    }
}

