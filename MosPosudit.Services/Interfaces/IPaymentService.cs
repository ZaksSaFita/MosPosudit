namespace MosPosudit.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<bool> ProcessPayPalReturnAsync(string orderId, int rentalId);
    }
}

