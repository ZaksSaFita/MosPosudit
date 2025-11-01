namespace MosPosudit.Model.SearchObjects
{
    public class PaymentSearchObject : BaseSearchObject
    {
        public int? OrderId { get; set; }
        public bool? IsCompleted { get; set; }
        public DateTime? PaymentDateFrom { get; set; }
        public DateTime? PaymentDateTo { get; set; }
    }
}

