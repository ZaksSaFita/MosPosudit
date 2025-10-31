using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Services.DataBase.Data
{
    public class Role
    {
        [Key]
        public int Id { get; set; }

        public string? Name { get; set; }

        public string Description { get; set; } = string.Empty;

        // Navigation properties
        public ICollection<User> Users { get; set; } = new List<User>();
    }
} 
