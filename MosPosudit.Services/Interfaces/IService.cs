using MosPosudit.Model.Responses;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface IService<T, TSearch> where T : class where TSearch : BaseSearchObject
    {
        Task<PagedResult<T>> GetAsync(TSearch search);
        Task<T?> GetByIdAsync(int id);
    }
}

