using MošPosudit.Model.DTOs;
using MošPosudit.Model.SearchObjects;
using MošPosudit.Model.Responses;

namespace MošPosudit.Services.Interfaces
{
    public interface IUserService
    {
        Task<UserResponse> GetById(int id);
        Task<PagedResult<UserResponse>> Get(UserSearchObject search);
        Task<UserResponse> Insert(UserInsertRequest request);
        Task<UserResponse> Update(int id, UserUpdateRequest request);
        Task<UserResponse> Delete(int id);
        Task<UserResponse> Login(string username, string password);
        Task<UserResponse> Register(UserInsertRequest request);
        Task<UserResponse> ChangePassword(int id, string oldPassword, string newPassword);
        Task<UserResponse> Deactivate(int id);
        Task<UserResponse> Activate(int id);
    }
} 