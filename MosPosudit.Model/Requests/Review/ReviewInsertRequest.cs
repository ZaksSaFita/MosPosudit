using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Review
{
    public class ReviewInsertRequest
    {
        [Required(ErrorMessage = "Tool ID is required")]
        public int ToolId { get; set; }

        [Required(ErrorMessage = "Rental ID is required")]
        public int RentalId { get; set; }

        [Required(ErrorMessage = "Rating is required")]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5")]
        public int Rating { get; set; }

        [StringLength(1000, ErrorMessage = "Comment cannot be longer than 1000 characters")]
        public string? Comment { get; set; }

        // UserId will be set from authenticated user context
        public int UserId { get; set; }
    }
}

