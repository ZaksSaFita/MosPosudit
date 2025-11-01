using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Order
{
    public class OrderItemInsertRequest
    {
        [Required(ErrorMessage = "Tool ID is required")]
        public int ToolId { get; set; }

        [Required(ErrorMessage = "Quantity is required")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; }
    }
}

