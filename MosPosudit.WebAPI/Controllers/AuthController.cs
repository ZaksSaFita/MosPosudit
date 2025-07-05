using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authentication.MicrosoftAccount;
using Microsoft.AspNetCore.Authentication.Facebook;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Auth;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IOAuthService _oauthService;
        private readonly IAuthService _authService;
        private readonly IMessageService _messageService;

        public AuthController(IOAuthService oauthService, IAuthService authService, IMessageService messageService)
        {
            _oauthService = oauthService;
            _authService = authService;
            _messageService = messageService;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                var response = await _authService.Login(request);
                
                // Send welcome notification
                if (response.UserId.HasValue)
                {
                    _messageService.PublishNotification(
                        response.UserId.Value,
                        "Welcome Back!",
                        "You have successfully logged in to MosPosudit.",
                        "Info"
                    );
                }
                
                return Ok(new { token = response.Token });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("google")]
        public IActionResult GoogleLogin()
        {
            var properties = _oauthService.ConfigureGoogleAuth();
            return Challenge(properties, GoogleDefaults.AuthenticationScheme);
        }

        [HttpGet("microsoft")]
        public IActionResult MicrosoftLogin()
        {
            var properties = _oauthService.ConfigureMicrosoftAuth();
            return Challenge(properties, MicrosoftAccountDefaults.AuthenticationScheme);
        }

        [HttpGet("facebook")]
        public IActionResult FacebookLogin()
        {
            var properties = _oauthService.ConfigureFacebookAuth();
            return Challenge(properties, FacebookDefaults.AuthenticationScheme);
        }

        [HttpGet("google-callback")]
        public async Task<IActionResult> GoogleCallback()
        {
            var result = await HttpContext.AuthenticateAsync(GoogleDefaults.AuthenticationScheme);
            if (!result.Succeeded)
                return BadRequest("Google authentication failed");

            var principal = await _oauthService.HandleGoogleCallback(result.Principal);
            await HttpContext.SignInAsync("OAuth", principal);

            return Redirect("/");
        }

        [HttpGet("microsoft-callback")]
        public async Task<IActionResult> MicrosoftCallback()
        {
            var result = await HttpContext.AuthenticateAsync(MicrosoftAccountDefaults.AuthenticationScheme);
            if (!result.Succeeded)
                return BadRequest("Microsoft authentication failed");

            var principal = await _oauthService.HandleMicrosoftCallback(result.Principal);
            await HttpContext.SignInAsync("OAuth", principal);

            return Redirect("/");
        }

        [HttpGet("facebook-callback")]
        public async Task<IActionResult> FacebookCallback()
        {
            var result = await HttpContext.AuthenticateAsync(FacebookDefaults.AuthenticationScheme);
            if (!result.Succeeded)
                return BadRequest("Facebook authentication failed");

            var principal = await _oauthService.HandleFacebookCallback(result.Principal);
            await HttpContext.SignInAsync("OAuth", principal);

            return Redirect("/");
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("logout")]
        public IActionResult Logout()
        {
            // JWT logout - we can't actually invalidate the token on the server side
            // but we can return a success response and let the client remove the token
            return Ok(new { message = "Successfully logged out" });
        }
    }
} 
