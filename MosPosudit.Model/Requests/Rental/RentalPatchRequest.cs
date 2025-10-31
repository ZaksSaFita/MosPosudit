namespace MosPosudit.Model.Requests.Rental
{
    public class RentalPatchRequest
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int? StatusId { get; set; }
        public string? Notes { get; set; }
        public bool? IsReturned { get; set; }
        public DateTime? ReturnDate { get; set; }
        public string? ReturnNotes { get; set; }
    }
}

