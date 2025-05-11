using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Services.DataBase.Data
{
    public class ToolImage
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ToolId { get; set; }

        [Required]
        [MaxLength(200)]
        public string ImageUrl { get; set; }

        public bool IsPrimary { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        public Tool Tool { get; set; }
    }
} 