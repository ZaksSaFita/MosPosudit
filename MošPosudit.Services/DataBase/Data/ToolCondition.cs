using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Services.DataBase.Data
{
    public class ToolCondition
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; }

        [MaxLength(255)]
        public string Description { get; set; }

        // Navigation properties
        public ICollection<Tool> Tools { get; set; }
    }
} 