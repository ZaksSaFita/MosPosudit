using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Category
{
    public class CategoryInsertRequest
    {
        [Required(ErrorMessage = "Category name is required")]
        [StringLength(100, ErrorMessage = "Category name cannot be longer than 100 characters")]
        public string Name { get; set; } = string.Empty;

        [StringLength(500, ErrorMessage = "Description cannot be longer than 500 characters")]
        public string? Description { get; set; }

        public string? ImageBase64 { get; set; }
    }
}

