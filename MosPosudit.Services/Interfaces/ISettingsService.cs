using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface ISettingsService
    {
        /// <summary>
        /// Gets the current recommendation settings (creates default if none exist)
        /// </summary>
        Task<RecommendationSettings> GetRecommendationSettingsAsync();

        /// <summary>
        /// Updates the recommendation settings
        /// </summary>
        Task<RecommendationSettings> UpdateRecommendationSettingsAsync(RecommendationSettings settings);
    }
}

