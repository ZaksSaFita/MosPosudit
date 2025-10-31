using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class ToolImage
    {
        [Key]
        public int Id { get; set; }

        public int ToolId { get; set; }

        public string? ImageUrl { get; set; }

        public bool IsPrimary { get; set; }

        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }
    }
} 
