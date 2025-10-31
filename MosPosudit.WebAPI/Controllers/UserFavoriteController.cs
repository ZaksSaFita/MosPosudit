using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.Requests.UserFavorite;
using MosPosudit.Model.Responses.UserFavorite;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UserFavoriteController : ControllerBase
    {
        private readonly IUserFavoriteService _favoriteService;

        public UserFavoriteController(IUserFavoriteService favoriteService)
        {
            _favoriteService = favoriteService ?? throw new ArgumentNullException(nameof(favoriteService));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserFavoriteResponse>>> Get([FromQuery] UserFavoriteSearchObject? search = null)
        {
            try
            {
                // Get user ID from authenticated user context
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
                {
                    // Override search with authenticated user ID
                    search ??= new UserFavoriteSearchObject();
                    search.UserId = userId;
                }
                else if (search?.UserId == null)
                {
                    return Unauthorized("User ID is required");
                }

                var result = await _favoriteService.GetAsResponse(search);
                return Ok(result);
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

        [HttpGet("{id}")]
        public async Task<ActionResult<UserFavoriteResponse>> GetById(int id)
        {
            try
            {
                var result = await _favoriteService.GetByIdAsResponse(id);
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

        [HttpPost]
        public async Task<ActionResult<UserFavoriteResponse>> Insert([FromBody] UserFavoriteInsertRequest insert)
        {
            try
            {
                if (insert == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                // Get user ID from authenticated user context
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    // For testing without auth, allow userId in request body
                    if (insert.UserId == 0)
                        return Unauthorized("User ID is required");
                    userId = insert.UserId;
                }
                else
                {
                    insert.UserId = userId;
                }

                var result = await _favoriteService.InsertAsResponse(insert);
                return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpDelete("tool/{toolId}")]
        public async Task<ActionResult> DeleteByTool(int toolId)
        {
            try
            {
                // Get user ID from authenticated user context
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    return Unauthorized("User ID is required");
                }

                var deleted = await _favoriteService.DeleteByUserAndTool(userId, toolId);
                if (!deleted)
                    return NotFound("Favorite not found");

                return Ok(new { message = "Favorite removed successfully" });
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpGet("check/{toolId}")]
        public async Task<ActionResult<bool>> IsFavorite(int toolId)
        {
            try
            {
                // Get user ID from authenticated user context
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    return Unauthorized("User ID is required");
                }

                var isFavorite = await _favoriteService.IsFavorite(userId, toolId);
                return Ok(new { isFavorite });
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }
    }
}

