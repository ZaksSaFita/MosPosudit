using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Order
{
    public class OrderInsertRequest
    {
        [Required(ErrorMessage = "User ID is required")]
        public int UserId { get; set; }

        [Required(ErrorMessage = "Start date is required")]
        public DateTime StartDate { get; set; }

        [Required(ErrorMessage = "End date is required")]
        public DateTime EndDate { get; set; }

        [Required(ErrorMessage = "Terms must be accepted")]
        public bool TermsAccepted { get; set; }

        [Required(ErrorMessage = "Order items are required")]
        [MinLength(1, ErrorMessage = "At least one order item is required")]
        public List<OrderItemInsertRequest> OrderItems { get; set; } = new List<OrderItemInsertRequest>();
    }
}

