using MošPosudit.Model.Requests.Auth;
using MošPosudit.Model.Responses.Auth;

namespace MošPosudit.Services.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponse> Login(LoginRequest request);
    }
} 