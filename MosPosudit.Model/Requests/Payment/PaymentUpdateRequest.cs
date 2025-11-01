using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Payment
{
    public class PaymentUpdateRequest
    {
        [Range(0.01, 100000, ErrorMessage = "Amount must be between 0.01 and 100000")]
        public decimal? Amount { get; set; }

        public bool? IsCompleted { get; set; }

        public string? TransactionId { get; set; }

        public DateTime? PaymentDate { get; set; }
    }
}

