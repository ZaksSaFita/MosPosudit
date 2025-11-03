using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.User;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.User;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : BaseCrudController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;

        public UserController(IUserService service) : base(service)
        {
            _userService = service;
        }

        [HttpGet]
        [Authorize]
        public override async Task<PagedResult<UserResponse>> Get([FromQuery] UserSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<UserResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override async Task<UserResponse> Create([FromBody] UserInsertRequest request)
        {
            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<UserResponse?> Update(int id, [FromBody] UserUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<ActionResult<UserResponse>> Register([FromBody] UserRegisterRequest request)
        {
            var result = await _userService.Register(request);
            return CreatedAtAction(nameof(GetUserDetails), new { id = result.Id }, result);
        }

        [HttpGet("{id}/details")]
        [Authorize]
        public async Task<ActionResult<UserResponse>> GetUserDetails(int id)
        {
            var result = await _userService.GetUserDetails(id);
            return Ok(result);
        }

        [HttpPost("{id}/deactivate")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> DeactivateUser(int id)
        {
            await _userService.DeactivateUser(id);
            return Ok("User deactivated successfully");
        }

        [HttpPost("{id}/activate")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> ActivateUser(int id)
        {
            await _userService.ActivateUser(id);
            return Ok("User activated successfully");
        }

        [HttpPost("update-profile")]
        [Authorize]
        public async Task<ActionResult<UserResponse>> UpdateProfile([FromBody] UserProfileUpdateRequest request)
        {
            var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                return Unauthorized();
            }

            var result = await _userService.UpdateProfile(userId, request);
            return Ok(result);
        }

        [HttpPost("{id}/change-password")]
        [Authorize]
        public async Task<ActionResult> ChangePassword(int id, [FromBody] ChangePasswordRequest request)
        {
            await _userService.ChangePassword(id, request.CurrentPassword, request.NewPassword);
            return Ok("Password changed successfully");
        }

        [HttpPost("{id}/verify-password")]
        [Authorize]
        public async Task<ActionResult<bool>> VerifyPassword(int id, [FromBody] string currentPassword)
        {
            var isValid = await _userService.VerifyCurrentPassword(id, currentPassword);
            return Ok(isValid);
        }

        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<ActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            await _userService.SendPasswordResetEmail(request.Email);
            return Ok("If the email exists in our system, you will receive a password reset link.");
        }

        [HttpGet("check-username/{username}")]
        [AllowAnonymous]
        public async Task<ActionResult<bool>> CheckUsernameExists(string username)
        {
            var exists = await _userService.CheckUsernameExists(username);
            return Ok(exists);
        }

        [HttpGet("check-email/{email}")]
        [AllowAnonymous]
        public async Task<ActionResult<bool>> CheckEmailExists(string email)
        {
            var exists = await _userService.CheckEmailExists(email);
            return Ok(exists);
        }

        [HttpGet("active")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<IEnumerable<UserResponse>>> GetActiveUsers()
        {
            var users = await _userService.GetActiveUsers();
            return Ok(users);
        }

        [HttpGet("inactive")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<IEnumerable<UserResponse>>> GetInactiveUsers()
        {
            var users = await _userService.GetInactiveUsers();
            return Ok(users);
        }

        [HttpGet("non-admins")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<UserResponse>>> GetNonAdminUsers()
        {
            var users = await _userService.GetNonAdminUsers();
            return Ok(users);
        }

        [HttpPost("{id}/upload-picture")]
        [Authorize]
        public async Task<ActionResult<UserResponse>> UploadPicture(int id, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No picture provided for upload.");

            byte[] pictureBytes;
            using (var ms = new MemoryStream())
            {
                await file.CopyToAsync(ms);
                pictureBytes = ms.ToArray();
            }

            var result = await _userService.UploadPicture(id, pictureBytes);
            return Ok(result);
        }

        [HttpDelete("{id}/picture")]
        [Authorize]
        public async Task<ActionResult> DeletePicture(int id)
        {
            await _userService.DeletePicture(id);
            return Ok("Picture deleted successfully");
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<UserResponse>> GetMe()
        {
            var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                return Unauthorized();
            }

            var result = await _userService.GetMe(userId);
            return Ok(result);
        }
    }
}
