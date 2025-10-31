using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class Category
    {
        [Key]
        public int Id { get; set; }

        public string? Name { get; set; }

        public string? Description { get; set; }

        // Image stored as base64 (null for seeded data - Flutter will load from assets based on name)
        public string? ImageBase64 { get; set; }

        // Navigation properties
        public ICollection<Tool> Tools { get; set; }
    }
} 
