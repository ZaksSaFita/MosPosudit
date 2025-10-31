namespace MosPosudit.Model.Responses.Rental
{
    public class RentalResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int StatusId { get; set; }
        public string? StatusName { get; set; }
        public decimal TotalPrice { get; set; }
        public decimal TotalAmount { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public string? Notes { get; set; }
        public bool IsReturned { get; set; }
        public DateTime? ReturnDate { get; set; }
        public string? ReturnNotes { get; set; }
        public bool TermsAccepted { get; set; }
        public DateTime? TermsAcceptedAt { get; set; }
        public bool ConfirmationEmailSent { get; set; }
        public DateTime? ConfirmationEmailSentAt { get; set; }
        public List<RentalItemResponse> Items { get; set; } = new();
    }

    public class RentalItemResponse
    {
        public int Id { get; set; }
        public int RentalId { get; set; }
        public int ToolId { get; set; }
        public string? ToolName { get; set; }
        public int Quantity { get; set; }
        public decimal DailyRate { get; set; }
        public string? Notes { get; set; }
    }
}

