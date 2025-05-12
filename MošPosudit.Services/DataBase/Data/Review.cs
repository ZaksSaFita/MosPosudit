using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class Review
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public int ToolId { get; set; }

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        [Required]
        [StringLength(1000)]
        public string? Comment { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public User User { get; set; }
        [ForeignKey("ToolId")]
        public Tool Tool { get; set; }

        // Logging properties
        [NotMapped]
        public string EntityName => "Review";

        [NotMapped]
        public string DisplayName => $"Review by {User?.Username} for {Tool?.Name}";
    }
} 