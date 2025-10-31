using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Auth;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly IMessageService _messageService;

        public AuthController(IAuthService authService, IMessageService messageService)
        {
            _authService = authService;
            _messageService = messageService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
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


        [HttpPost("logout")]
        [Authorize]
        public IActionResult Logout()
        {
            // JWT logout - we can't actually invalidate the token on the server side
            // but we can return a success response and let the client remove the token
            return Ok(new { message = "Successfully logged out" });
        }
    }
} 
