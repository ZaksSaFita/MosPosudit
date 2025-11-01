using MosPosudit.Model.Requests.Payment;
using MosPosudit.Model.Responses.Payment;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface IPaymentService : ICrudService<PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest>
    {
        Task<PayPalOrderResponse> CreatePayPalOrderAsync(PayPalCreateOrderRequest request);
        Task<PayPalCaptureResponse> CompletePayPalPaymentAsync(string paypalOrderId);
    }
}

