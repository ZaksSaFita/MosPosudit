using Microsoft.AspNetCore.Authentication;
using System.Security.Claims;

namespace MošPosudit.Services.Interfaces
{
    public interface IOAuthService
    {

        AuthenticationProperties ConfigureGoogleAuth();

        AuthenticationProperties ConfigureMicrosoftAuth();


        AuthenticationProperties ConfigureFacebookAuth();

        Task<ClaimsPrincipal> HandleGoogleCallback(ClaimsPrincipal principal);


        Task<ClaimsPrincipal> HandleMicrosoftCallback(ClaimsPrincipal principal);


        Task<ClaimsPrincipal> HandleFacebookCallback(ClaimsPrincipal principal);
    }
}