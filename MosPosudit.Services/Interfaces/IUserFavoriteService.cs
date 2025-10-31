using MosPosudit.Model.Requests.UserFavorite;
using MosPosudit.Model.Responses.UserFavorite;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface IUserFavoriteService
    {
        Task<IEnumerable<UserFavoriteResponse>> GetAsResponse(UserFavoriteSearchObject? search = null);
        Task<UserFavoriteResponse> GetByIdAsResponse(int id);
        Task<UserFavoriteResponse> InsertAsResponse(UserFavoriteInsertRequest insert);
        Task<bool> DeleteByUserAndTool(int userId, int toolId);
        Task<bool> IsFavorite(int userId, int toolId);
    }
}

