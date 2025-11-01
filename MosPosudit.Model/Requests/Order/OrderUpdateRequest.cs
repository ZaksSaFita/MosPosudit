using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Order
{
    public class OrderUpdateRequest
    {
        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Range(0, 100000, ErrorMessage = "Total amount must be between 0 and 100000")]
        public decimal? TotalAmount { get; set; }

        public bool? IsReturned { get; set; }

        public DateTime? ReturnDate { get; set; }
    }
}

