using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.Requests.User;
using MosPosudit.Model.Responses.User;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UserController : BaseCrudController<User, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
            : base((ICrudService<User, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>)userService)
        {
            _userService = userService;
        }

        // Public endpoints
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<ActionResult<UserResponse>> Register([FromBody] UserRegisterRequest request)
        {
            try
            {
                if (request == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _userService.RegisterAsResponse(request);
                return CreatedAtAction(nameof(GetUserDetails), new { id = result.Id }, result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (ConflictException ex)
            {
                return Conflict(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        // Admin only endpoints
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override async Task<ActionResult<User>> Insert([FromBody] UserInsertRequest request)
        {
            return await base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<ActionResult<User>> Update(int id, [FromBody] UserUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        // User endpoints
        [HttpPatch("{id}")]
        public override async Task<ActionResult<User>> Patch(int id, [FromBody] UserPatchRequest request)
        {
            return await base.Patch(id, request);
        }

        protected override int GetId(User entity)
        {
            return entity.Id;
        }

        [HttpGet("{id}")]
        public override async Task<ActionResult<User>> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpGet("{id}/details")]
        public async Task<ActionResult<UserResponse>> GetUserDetails(int id)
        {
            try
            {
                var result = await _userService.GetUserDetailsAsResponse(id);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPost("{id}/deactivate")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> DeactivateUser(int id)
        {
            try
            {
                await _userService.DeactivateUser(id);
                return Ok(SuccessMessages.UserDeactivated);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [HttpPost("{id}/activate")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult> ActivateUser(int id)
        {
            try
            {
                await _userService.ActivateUser(id);
                return Ok(SuccessMessages.UserActivated);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [HttpPost("update-profile")]
        public async Task<ActionResult<UserResponse>> UpdateProfile([FromBody] UserProfileUpdateRequest request)
        {
            try
            {
                var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == System.Security.Claims.ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    return Unauthorized();
                }

                var result = await _userService.UpdateProfileAsResponse(userId, request);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (ConflictException ex)
            {
                return Conflict(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPost("{id}/change-password")]
        public async Task<ActionResult> ChangePassword(int id, [FromBody] ChangePasswordRequest request)
        {
            try
            {
                await _userService.ChangePassword(id, request.CurrentPassword, request.NewPassword);
                return Ok(SuccessMessages.PasswordChanged);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("{id}/verify-password")]
        public async Task<ActionResult<bool>> VerifyPassword(int id, [FromBody] string currentPassword)
        {
            try
            {
                var isValid = await _userService.VerifyCurrentPassword(id, currentPassword);
                return Ok(isValid);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<ActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            try
            {
                var success = await _userService.SendPasswordResetEmail(request.Email);
                if (success)
                {
                    return Ok("If the email exists in our system, you will receive a password reset link.");
                }
                return Ok("If the email exists in our system, you will receive a password reset link.");
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
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
        public async Task<ActionResult<IEnumerable<User>>> GetActiveUsers()
        {
            var users = await _userService.GetActiveUsers();
            return Ok(users);
        }

        [HttpGet("inactive")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<IEnumerable<User>>> GetInactiveUsers()
        {
            var users = await _userService.GetInactiveUsers();
            return Ok(users);
        }

        [HttpGet("non-admins")]
        public async Task<ActionResult<IEnumerable<User>>> GetNonAdminUsers()
        {
            var users = await _userService.GetNonAdminUsers();
            return Ok(users);
        }

        [HttpPost("{id}/upload-picture")]
        public async Task<ActionResult<UserResponse>> UploadPicture(int id, IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                    return BadRequest("Nema slike za upload.");

                byte[] pictureBytes;
                using (var ms = new MemoryStream())
                {
                    await file.CopyToAsync(ms);
                    pictureBytes = ms.ToArray();
                }

                var result = await _userService.UploadPictureAsResponse(id, pictureBytes);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpDelete("{id}/picture")]
        public async Task<ActionResult> DeletePicture(int id)
        {
            try
            {
                await _userService.DeletePictureAsResponse(id);
                return Ok("Slika uspješno uklonjena.");
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpGet("me")]
        public async Task<ActionResult<UserResponse>> GetMe()
        {
            try
            {
                var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == System.Security.Claims.ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    return Unauthorized();
                }

                var result = await _userService.GetMeAsResponse(userId);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }
    }
}
