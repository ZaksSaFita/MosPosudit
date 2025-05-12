using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MošPosudit.Model.Exceptions;
using MošPosudit.Model.Messages;
using MošPosudit.Model.Requests.User;
using MošPosudit.Model.SearchObjects;
using MošPosudit.Services.DataBase.Data;
using MošPosudit.Services.Interfaces;

namespace MošPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
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
        public async Task<ActionResult<User>> Register([FromBody] UserRegisterRequest request)
        {
            try
            {
                if (request == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                // Konvertujemo RegisterRequest u InsertRequest i postavljamo RoleId na User
                var insertRequest = new UserInsertRequest
                {
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    Email = request.Email,
                    PhoneNumber = request.PhoneNumber,
                    Address = request.Address,
                    Username = request.Username,
                    Password = request.Password,
                    RoleId = 2 // Pretpostavljamo da je 2 ID za User rolu
                };

                var result = await _userService.Insert(insertRequest);
                return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
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
        [Authorize]
        public override async Task<ActionResult<User>> Patch(int id, [FromBody] UserPatchRequest request)
        {
            // Dodatna provjera - korisnik može mijenjati samo svoj profil
            var userId = int.Parse(User.FindFirst("UserId")?.Value);
            if (userId != id)
                return Forbid();

            return await base.Patch(id, request);
        }

        protected override int GetId(User entity)
        {
            return entity.Id;
        }

        [HttpPost("{id}/deactivate")]
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

        [HttpPost("{id}/change-password")]
        public async Task<ActionResult> ChangePassword(int id, [FromBody] ChangePasswordRequest request)
        {
            try
            {
                await _userService.ChangePassword(id, request.NewPassword);
                return Ok(SuccessMessages.PasswordChanged);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [HttpGet("check-username/{username}")]
        public async Task<ActionResult<bool>> CheckUsernameExists(string username)
        {
            var exists = await _userService.CheckUsernameExists(username);
            return Ok(exists);
        }

        [HttpGet("check-email/{email}")]
        public async Task<ActionResult<bool>> CheckEmailExists(string email)
        {
            var exists = await _userService.CheckEmailExists(email);
            return Ok(exists);
        }

        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<User>>> GetActiveUsers()
        {
            var users = await _userService.GetActiveUsers();
            return Ok(users);
        }

        [HttpGet("inactive")]
        public async Task<ActionResult<IEnumerable<User>>> GetInactiveUsers()
        {
            var users = await _userService.GetInactiveUsers();
            return Ok(users);
        }
    }
}