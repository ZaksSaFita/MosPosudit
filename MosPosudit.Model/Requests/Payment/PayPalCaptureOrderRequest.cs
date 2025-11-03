using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Payment
{
    public class PayPalCaptureOrderRequest
    {
        [Required(ErrorMessage = "PayPal Order ID is required")]
        public string PayPalOrderId { get; set; } = string.Empty;
    }
}

