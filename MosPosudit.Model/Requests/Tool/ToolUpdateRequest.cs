using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Tool
{
    public class ToolUpdateRequest
    {
        [StringLength(100, ErrorMessage = "Tool name cannot be longer than 100 characters")]
        public string? Name { get; set; }

        [StringLength(500, ErrorMessage = "Description cannot be longer than 500 characters")]
        public string? Description { get; set; }

        public int? CategoryId { get; set; }

        [Range(0.01, 10000, ErrorMessage = "Daily rate must be between 0.01 and 10000")]
        public decimal? DailyRate { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int? Quantity { get; set; }

        [Range(0, 10000, ErrorMessage = "Deposit amount must be between 0 and 10000")]
        public decimal? DepositAmount { get; set; }

        public bool? IsAvailable { get; set; }

        // Image as base64 string (for uploaded images)
        public string? ImageBase64 { get; set; }
    }
}

