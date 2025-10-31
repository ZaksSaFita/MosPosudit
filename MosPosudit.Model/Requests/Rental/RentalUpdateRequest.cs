using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Rental
{
    public class RentalUpdateRequest
    {
        [Required(ErrorMessage = "Start date is required")]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = "End date is required")]
        public DateTime EndDate { get; set; }

        [Required(ErrorMessage = "Status ID is required")]
        public int StatusId { get; set; }

        public string? Notes { get; set; }
    }
}

