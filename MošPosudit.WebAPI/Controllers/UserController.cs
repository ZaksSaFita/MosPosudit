using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MošPosudit.Model.DTOs;
using MošPosudit.Model.SearchObjects;
using MošPosudit.Services.Interfaces;

namespace MošPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetById(int id)
        {
            var user = await _userService.GetById(id);
            return Ok(user);
        }

        [HttpGet]
        // [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Get([FromQuery] UserSearchObject search)
        {
            var users = await _userService.Get(search);
            return Ok(users);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Insert([FromBody] UserInsertRequest request)
        {
            var user = await _userService.Insert(request);
            return CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
        }

        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> Update(int id, [FromBody] UserUpdateRequest request)
        {
            var user = await _userService.Update(id, request);
            return Ok(user);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(int id)
        {
            var user = await _userService.Delete(id);
            return Ok(user);
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _userService.Login(request.Username, request.Password);
            return Ok(user);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] UserInsertRequest request)
        {
            var user = await _userService.Register(request);
            return CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
        }

        [HttpPost("{id}/change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword(int id, [FromBody] ChangePasswordRequest request)
        {
            var user = await _userService.ChangePassword(id, request.OldPassword, request.NewPassword);
            return Ok(user);
        }

        [HttpPost("{id}/deactivate")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var user = await _userService.Deactivate(id);
            return Ok(user);
        }

        [HttpPost("{id}/activate")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Activate(int id)
        {
            var user = await _userService.Activate(id);
            return Ok(user);
        }
    }
}