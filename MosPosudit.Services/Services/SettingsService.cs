using Microsoft.EntityFrameworkCore;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class SettingsService : ISettingsService
    {
        private readonly ApplicationDbContext _context;

        public SettingsService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<RecommendationSettings> GetRecommendationSettingsAsync()
        {
            try
            {
                var settings = await _context.RecommendationSettings.FirstOrDefaultAsync();

                // If no settings exist, create default ones
                if (settings == null)
                {
                    settings = new RecommendationSettings
                    {
                        HomePopularWeight = 40.0,
                        HomeContentBasedWeight = 30.0,
                        HomeTopRatedWeight = 30.0,
                        CartFrequentlyBoughtWeight = 60.0,
                        CartSimilarToolsWeight = 40.0,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };

                    _context.RecommendationSettings.Add(settings);
                    await _context.SaveChangesAsync();
                }

                return settings;
            }
            catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 208) // Invalid object name
            {
                throw new InvalidOperationException(
                    "RecommendationSettings table does not exist. Please run database migrations. " +
                    $"Error details: {ex.Message}", ex);
            }
        }

        public async Task<RecommendationSettings> UpdateRecommendationSettingsAsync(RecommendationSettings settings)
        {
            // Validate that home weights sum to 100
            var homeTotal = settings.HomePopularWeight + settings.HomeContentBasedWeight + settings.HomeTopRatedWeight;
            if (Math.Abs(homeTotal - 100.0) > 0.01)
            {
                throw new ArgumentException($"Home recommendation weights must sum to 100%. Current sum: {homeTotal}%");
            }

            // Validate that cart weights sum to 100
            var cartTotal = settings.CartFrequentlyBoughtWeight + settings.CartSimilarToolsWeight;
            if (Math.Abs(cartTotal - 100.0) > 0.01)
            {
                throw new ArgumentException($"Cart recommendation weights must sum to 100%. Current sum: {cartTotal}%");
            }

            var existing = await _context.RecommendationSettings.FirstOrDefaultAsync();

            if (existing == null)
            {
                settings.CreatedAt = DateTime.UtcNow;
                settings.UpdatedAt = DateTime.UtcNow;
                _context.RecommendationSettings.Add(settings);
            }
            else
            {
                existing.HomePopularWeight = settings.HomePopularWeight;
                existing.HomeContentBasedWeight = settings.HomeContentBasedWeight;
                existing.HomeTopRatedWeight = settings.HomeTopRatedWeight;
                existing.CartFrequentlyBoughtWeight = settings.CartFrequentlyBoughtWeight;
                existing.CartSimilarToolsWeight = settings.CartSimilarToolsWeight;
                existing.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return existing ?? settings;
        }
    }
}

