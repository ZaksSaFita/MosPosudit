using MosPosudit.Model.Requests.Rental;
using MosPosudit.Model.Responses.Rental;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface IRentalService : ICrudService<Rental, RentalSearchObject, RentalInsertRequest, RentalUpdateRequest, RentalPatchRequest>
    {
        Task<IEnumerable<RentalResponse>> GetAsResponse(RentalSearchObject? search = null);
        Task<RentalResponse> GetByIdAsResponse(int id);
        Task<RentalResponse> InsertAsResponse(RentalInsertRequest insert);
        Task<RentalResponse> UpdateAsResponse(int id, RentalUpdateRequest update);
        Task<RentalResponse> PatchAsResponse(int id, RentalPatchRequest patch);
        Task<RentalResponse> DeleteAsResponse(int id);
        Task<IEnumerable<RentalResponse>> GetByUserId(int userId);
        Task<bool> CheckAvailability(int toolId, DateTime startDate, DateTime endDate);
        Task<IEnumerable<DateTime>> GetBookedDates(int toolId, DateTime? startDate, DateTime? endDate);
        Task<object> GeneratePaymentLinkAsync(int rentalId, string baseUrl);
    }
}

