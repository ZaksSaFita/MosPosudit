using MosPosudit.Model.Requests.Review;
using MosPosudit.Model.Responses.Review;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface IReviewService : ICrudService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        Task<IEnumerable<ReviewResponse>> GetByToolIdAsResponse(int toolId);
    }
}

