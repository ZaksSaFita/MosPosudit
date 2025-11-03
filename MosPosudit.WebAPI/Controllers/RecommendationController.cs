using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _recommendationService;

        public RecommendationController(IRecommendationService recommendationService)
        {
            _recommendationService = recommendationService;
        }

        [HttpGet("home")]
        [Authorize]
        public async Task<ActionResult> GetHomeRecommendations([FromQuery] int count = 6)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    return Unauthorized(new { message = "User ID is required" });
                }

                var recommendations = await _recommendationService.GetHomeRecommendationsAsync(userId, count);
                return Ok(recommendations);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("cart/{toolId}")]
        [Authorize]
        public async Task<ActionResult> GetCartRecommendations(int toolId, [FromQuery] int count = 3)
        {
            try
            {
                var recommendations = await _recommendationService.GetCartRecommendationsAsync(toolId, count);
                return Ok(recommendations);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}

