using MosPosudit.Model.Requests.UserFavorite;
using MosPosudit.Model.Responses.UserFavorite;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface IUserFavoriteService : ICrudService<UserFavoriteResponse, UserFavoriteSearchObject, UserFavoriteInsertRequest, UserFavoriteUpdateRequest>
    {
        Task<bool> DeleteByUserAndTool(int userId, int toolId);
        Task<bool> IsFavorite(int userId, int toolId);
    }
}

