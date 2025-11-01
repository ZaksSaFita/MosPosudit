using System.ComponentModel.DataAnnotations;
using MosPosudit.Model.Requests.Order;

namespace MosPosudit.Model.Requests.Payment
{
    public class PayPalCreateOrderRequest
    {
        [Required(ErrorMessage = "Order data is required")]
        public OrderInsertRequest OrderData { get; set; } = null!;
    }
}

