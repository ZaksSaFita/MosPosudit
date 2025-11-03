using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Tool
{
    public class ToolInsertRequest
    {
        [Required(ErrorMessage = "Tool name is required")]
        [StringLength(100, ErrorMessage = "Tool name cannot be longer than 100 characters")]
        public string Name { get; set; } = string.Empty;

        [StringLength(500, ErrorMessage = "Description cannot be longer than 500 characters")]
        public string? Description { get; set; }

        [Required(ErrorMessage = "Category ID is required")]
        public int CategoryId { get; set; }

        [Required(ErrorMessage = "Daily rate is required")]
        [Range(0.01, 10000, ErrorMessage = "Daily rate must be between 0.01 and 10000")]
        public decimal DailyRate { get; set; }

        [Required(ErrorMessage = "Quantity is required")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; } = 1;

        [Range(0, 10000, ErrorMessage = "Deposit amount must be between 0 and 10000")]
        public decimal DepositAmount { get; set; } = 0;

        public bool IsAvailable { get; set; } = true;
        public string? ImageBase64 { get; set; }
    }
}

