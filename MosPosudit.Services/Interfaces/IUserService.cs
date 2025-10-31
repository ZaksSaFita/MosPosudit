using MosPosudit.Model.Requests.User;
using MosPosudit.Model.Responses.User;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface IUserService : ICrudService<User, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>
    {
        // User status management
        Task<bool> ActivateUser(int id);
        Task<bool> DeactivateUser(int id);
        Task<IEnumerable<User>> GetActiveUsers();
        Task<IEnumerable<User>> GetInactiveUsers();
        Task<IEnumerable<User>> GetNonAdminUsers();

        // User authentication
        Task<bool> ChangePassword(int id, string currentPassword, string newPassword);
        Task<bool> VerifyCurrentPassword(int id, string currentPassword);
        Task<bool> SendPasswordResetEmail(string email);

        // Profile management
        Task<User> UpdateProfile(int userId, UserProfileUpdateRequest request);
        Task<UserResponse> UpdateProfileAsResponse(int userId, UserProfileUpdateRequest request);
        Task<UserResponse> GetUserDetailsAsResponse(int id);
        Task<UserResponse> GetMeAsResponse(int userId);
        Task<UserResponse> UploadPictureAsResponse(int userId, byte[] picture);
        Task<bool> DeletePictureAsResponse(int userId);
        Task<UserResponse> RegisterAsResponse(UserRegisterRequest request);

        // Validation methods
        Task<bool> CheckUsernameExists(string username);
        Task<bool> CheckEmailExists(string email);
    }
}
