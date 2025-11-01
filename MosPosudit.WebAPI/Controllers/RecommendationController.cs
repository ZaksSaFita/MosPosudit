using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Services.Interfaces;

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

        /// <summary>
        /// Gets personalized recommendations for home screen (4-6 tools)
        /// </summary>
        [HttpGet("home/{userId}")]
        [Authorize]
        public async Task<ActionResult> GetHomeRecommendations(int userId, [FromQuery] int count = 6)
        {
            try
            {
                var recommendations = await _recommendationService.GetHomeRecommendationsAsync(userId, count);
                return Ok(recommendations);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Gets recommendations when user adds item to cart (2-3 tools)
        /// </summary>
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

