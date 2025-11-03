using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface ISettingsService
    {
        // Gets the current recommendation settings (creates default if none exist)
        Task<RecommendationSettings> GetRecommendationSettingsAsync();

        // Updates the recommendation settings
        Task<RecommendationSettings> UpdateRecommendationSettingsAsync(RecommendationSettings settings);

        // Triggers immediate ML training by resetting LastTrainingDate
        Task TriggerMLTrainingAsync();
    }
}

