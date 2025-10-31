namespace MosPosudit.Model.Enums
{
    public enum RentalStatus
    {
        Pending = 1,      // Čeka admin odobrenje
        Active = 2,       // Aktivan rental (plaćen i odobren)
        Completed = 3,    // Završen (alat vraćen i potvrđen)
        Cancelled = 4     // Otkazan
    }
} 
