using MosPosudit.Model.Responses.Tool;

namespace MosPosudit.Services.Interfaces
{
    public interface IRecommendationService
    {
        /// <summary>
        /// Gets personalized recommendations for home screen (4-6 tools)
        /// Combination of: Popular, Content-based, Top Rated
        /// </summary>
        Task<List<ToolResponse>> GetHomeRecommendationsAsync(int userId, int count = 6);

        /// <summary>
        /// Gets recommendations when user adds item to cart (2-3 tools)
        /// Combination of: Frequently Bought Together + Similar Tools
        /// </summary>
        Task<List<ToolResponse>> GetCartRecommendationsAsync(int toolId, int count = 3);
    }
}

