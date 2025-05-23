using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authentication.MicrosoftAccount;
using Microsoft.AspNetCore.Authentication.Facebook;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MošPosudit.Model.Requests.Auth;
using MošPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MošPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IOAuthService _oauthService;
        private readonly IAuthService _authService;

        public AuthController(IOAuthService oauthService, IAuthService authService)
        {
            _oauthService = oauthService;
            _authService = authService;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                var response = await _authService.Login(request);
                return Ok(response);
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