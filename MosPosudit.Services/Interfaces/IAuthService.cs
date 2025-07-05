using MosPosudit.Model.Requests.Auth;
using MosPosudit.Model.Responses.Auth;

namespace MosPosudit.Services.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponse> Login(LoginRequest request);
    }
} 
