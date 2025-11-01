using MosPosudit.Model.Requests.User;
using MosPosudit.Model.Responses.User;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface IUserService : ICrudService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        // User status management
        Task<bool> ActivateUser(int id);
        Task<bool> DeactivateUser(int id);
        Task<IEnumerable<UserResponse>> GetActiveUsers();
        Task<IEnumerable<UserResponse>> GetInactiveUsers();
        Task<IEnumerable<UserResponse>> GetNonAdminUsers();

        // User authentication
        Task<bool> ChangePassword(int id, string currentPassword, string newPassword);
        Task<bool> VerifyCurrentPassword(int id, string currentPassword);
        Task<bool> SendPasswordResetEmail(string email);

        // Profile management
        Task<UserResponse> UpdateProfile(int userId, UserProfileUpdateRequest request);
        Task<UserResponse> GetUserDetails(int id);
        Task<UserResponse> GetMe(int userId);
        Task<UserResponse> UploadPicture(int userId, byte[] picture);
        Task<bool> DeletePicture(int userId);
        Task<UserResponse> Register(UserRegisterRequest request);

        // Validation methods
        Task<bool> CheckUsernameExists(string username);
        Task<bool> CheckEmailExists(string email);
    }
}
