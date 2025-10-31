using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Rental
{
    public class RentalInsertRequest
    {
        [Required(ErrorMessage = "Start date is required")]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = "End date is required")]
        public DateTime EndDate { get; set; }

        public string? Notes { get; set; }

        [Required(ErrorMessage = "At least one rental item is required")]
        [MinLength(1, ErrorMessage = "At least one rental item is required")]
        public List<RentalItemInsertRequest> Items { get; set; } = new();

        // UserId will be set from authenticated user context, not from request
        public int UserId { get; set; }
    }

    public class RentalItemInsertRequest
    {
        [Required(ErrorMessage = "Tool ID is required")]
        public int ToolId { get; set; }

        [Required(ErrorMessage = "Quantity is required")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; }

        [Required(ErrorMessage = "Daily rate is required")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Daily rate must be greater than 0")]
        public decimal DailyRate { get; set; }

        public string? Notes { get; set; }
    }
}

