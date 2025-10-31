using MosPosudit.Model.Requests.Review;
using MosPosudit.Model.Responses.Review;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface IReviewService : ICrudService<Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest, ReviewPatchRequest>
    {
        Task<IEnumerable<ReviewResponse>> GetAsResponse(ReviewSearchObject? search = null);
        Task<ReviewResponse> GetByIdAsResponse(int id);
        Task<ReviewResponse> InsertAsResponse(ReviewInsertRequest insert);
        Task<ReviewResponse> UpdateAsResponse(int id, ReviewUpdateRequest update);
        Task<ReviewResponse> PatchAsResponse(int id, ReviewPatchRequest patch);
        Task<ReviewResponse> DeleteAsResponse(int id);
        Task<IEnumerable<ReviewResponse>> GetByToolIdAsResponse(int toolId);
    }
}

