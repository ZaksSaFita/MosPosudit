using MosPosudit.Model.Responses.Tool;

namespace MosPosudit.Services.Interfaces
{
    public interface IRecommendationService
    {
        // Gets personalized recommendations for home screen
        Task<List<ToolResponse>> GetHomeRecommendationsAsync(int userId, int count = 6);

        // Gets recommendations when user adds item to cart
        Task<List<ToolResponse>> GetCartRecommendationsAsync(int toolId, int count = 3);
    }
}

