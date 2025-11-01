using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.UserFavorite;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.UserFavorite;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UserFavoriteController : BaseCrudController<UserFavoriteResponse, UserFavoriteSearchObject, UserFavoriteInsertRequest, UserFavoriteUpdateRequest>
    {
        private readonly IUserFavoriteService _favoriteService;

        public UserFavoriteController(IUserFavoriteService service) : base(service)
        {
            _favoriteService = service;
        }

        [HttpGet]
        public override async Task<Model.Responses.PagedResult<UserFavoriteResponse>> Get([FromQuery] UserFavoriteSearchObject? search = null)
        {
            // Get user ID from authenticated user context
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
            {
                search ??= new UserFavoriteSearchObject();
                search.UserId = userId;
            }
            return await base.Get(search);
        }

        [HttpPost]
        public override async Task<UserFavoriteResponse> Create([FromBody] UserFavoriteInsertRequest request)
        {
            // Get user ID from authenticated user context
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                if (request.UserId == 0)
                    throw new UnauthorizedAccessException("User ID is required");
                userId = request.UserId;
            }
            else
            {
                request.UserId = userId;
            }
            return await _favoriteService.CreateAsync(request);
        }

        [HttpDelete("tool/{toolId}")]
        public async Task<IActionResult> DeleteByTool(int toolId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                throw new UnauthorizedAccessException("User ID is required");
            }

            var deleted = await _favoriteService.DeleteByUserAndTool(userId, toolId);
            if (!deleted)
                return NotFound("Favorite not found");

            return Ok(new { message = "Favorite removed successfully" });
        }

        [HttpGet("check/{toolId}")]
        public async Task<IActionResult> IsFavorite(int toolId)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                throw new UnauthorizedAccessException("User ID is required");
            }

            var isFavorite = await _favoriteService.IsFavorite(userId, toolId);
            return Ok(new { isFavorite });
        }
    }
}

