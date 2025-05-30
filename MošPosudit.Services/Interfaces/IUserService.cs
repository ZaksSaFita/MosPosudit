using MošPosudit.Model.Requests.User;
using MošPosudit.Model.SearchObjects;
using MošPosudit.Services.DataBase.Data;

namespace MošPosudit.Services.Interfaces
{
    public interface IUserService : ICrudService<User, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>
    {
        // User status management
        Task<bool> ActivateUser(int id);
        Task<bool> DeactivateUser(int id);
        Task<IEnumerable<User>> GetActiveUsers();
        Task<IEnumerable<User>> GetInactiveUsers();

        // User authentication
        Task<bool> ChangePassword(int id, string newPassword);

        // Validation methods
        Task<bool> CheckUsernameExists(string username);
        Task<bool> CheckEmailExists(string email);
    }
}