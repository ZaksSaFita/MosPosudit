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

        [HttpPut("recommendations")]
        public async Task<ActionResult<RecommendationSettings>> UpdateRecommendationSettings([FromBody] RecommendationSettingsUpdateRequest request)
        {
            try
            {
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

                var settings = new RecommendationSettings
                {
                    Engine = (RecommendationEngine)request.Engine,
                    TrainingIntervalDays = request.TrainingIntervalDays,
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

        [HttpPost("recommendations/train")]
        public async Task<ActionResult> TriggerMLTraining()
        {
            try
            {
                var settings = await _settingsService.GetRecommendationSettingsAsync();
                
                if (settings.Engine == RecommendationEngine.RuleBased)
                {
                    return BadRequest(new { message = "ML training is not enabled. Please set engine to MachineLearning or Hybrid first." });
                }

                await _settingsService.TriggerMLTrainingAsync();
                
                return Ok(new { 
                    message = "ML training triggered successfully. Check worker logs for progress.",
                    note = "Training will start within 1-5 minutes and take 2-5 minutes to complete."
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error triggering ML training", error = ex.Message });
            }
        }
    }
}

