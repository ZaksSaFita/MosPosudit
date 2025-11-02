using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Settings;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class SettingsController : ControllerBase
    {
        private readonly ISettingsService _settingsService;

        public SettingsController(ISettingsService settingsService)
        {
            _settingsService = settingsService;
        }

        /// <summary>
        /// Gets the current recommendation settings
        /// </summary>
        [HttpGet("recommendations")]
        public async Task<ActionResult<RecommendationSettings>> GetRecommendationSettings()
        {
            try
            {
                var settings = await _settingsService.GetRecommendationSettingsAsync();
                return Ok(settings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving recommendation settings", error = ex.Message });
            }
        }

        /// <summary>
        /// Updates the recommendation settings
        /// </summary>
        [HttpPut("recommendations")]
        public async Task<ActionResult<RecommendationSettings>> UpdateRecommendationSettings([FromBody] RecommendationSettingsUpdateRequest request)
        {
            try
            {
                // Validate weights sum to 100
                var homeTotal = request.HomePopularWeight + request.HomeContentBasedWeight + request.HomeTopRatedWeight;
                if (Math.Abs(homeTotal - 100.0) > 0.01)
                {
                    return BadRequest(new { message = $"Home recommendation weights must sum to 100%. Current sum: {homeTotal}%" });
                }

                var cartTotal = request.CartFrequentlyBoughtWeight + request.CartSimilarToolsWeight;
                if (Math.Abs(cartTotal - 100.0) > 0.01)
                {
                    return BadRequest(new { message = $"Cart recommendation weights must sum to 100%. Current sum: {cartTotal}%" });
                }

                // Map request to entity
                var settings = new RecommendationSettings
                {
                    HomePopularWeight = request.HomePopularWeight,
                    HomeContentBasedWeight = request.HomeContentBasedWeight,
                    HomeTopRatedWeight = request.HomeTopRatedWeight,
                    CartFrequentlyBoughtWeight = request.CartFrequentlyBoughtWeight,
                    CartSimilarToolsWeight = request.CartSimilarToolsWeight
                };

                var updatedSettings = await _settingsService.UpdateRecommendationSettingsAsync(settings);
                return Ok(updatedSettings);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error updating recommendation settings", error = ex.Message });
            }
        }
    }
}

