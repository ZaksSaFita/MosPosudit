using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Responses.Tool;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public RecommendationService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        /// <summary>
        /// Gets personalized recommendations for home screen (4-6 tools)
        /// Combination: 40% Popular, 30% Content-based, 30% Top Rated
        /// </summary>
        public async Task<List<ToolResponse>> GetHomeRecommendationsAsync(int userId, int count = 6)
        {
            var recommendations = new List<ToolResponse>();
            var addedToolIds = new HashSet<int>();

            // 1. Get user's favorite categories from their orders (Content-based - 30%)
            var userFavoriteCategories = await GetUserFavoriteCategoriesAsync(userId);
            var contentBasedCount = (int)(count * 0.3);

            if (userFavoriteCategories.Any() && contentBasedCount > 0)
            {
                var contentBased = await GetContentBasedRecommendationsAsync(
                    userId, 
                    userFavoriteCategories, 
                    contentBasedCount,
                    addedToolIds
                );
                recommendations.AddRange(contentBased);
            }

            // 2. Get popular/trending tools (40%)
            var popularCount = (int)(count * 0.4);
            var popular = await GetPopularRecommendationsAsync(popularCount, addedToolIds);
            recommendations.AddRange(popular);

            // 3. Get top rated tools (30%)
            var topRatedCount = count - recommendations.Count;
            if (topRatedCount > 0)
            {
                var topRated = await GetTopRatedRecommendationsAsync(topRatedCount, addedToolIds);
                recommendations.AddRange(topRated);
            }

            // If we don't have enough, fill with any available tools
            if (recommendations.Count < count)
            {
                var remaining = count - recommendations.Count;
                var fillers = await GetAvailableToolsAsync(remaining, addedToolIds);
                recommendations.AddRange(fillers);
            }

            return recommendations.Take(count).ToList();
        }

        /// <summary>
        /// Gets recommendations when user adds item to cart (2-3 tools)
        /// Combination: Frequently Bought Together + Similar Tools
        /// </summary>
        public async Task<List<ToolResponse>> GetCartRecommendationsAsync(int toolId, int count = 3)
        {
            var recommendations = new List<ToolResponse>();
            var addedToolIds = new HashSet<int> { toolId };

            // 1. Frequently Bought Together (60% - 2 tools)
            var frequentlyBoughtCount = (int)(count * 0.6);
            var frequentlyBought = await GetFrequentlyBoughtTogetherAsync(toolId, frequentlyBoughtCount, addedToolIds);
            recommendations.AddRange(frequentlyBought);

            // 2. Similar Tools from same category (40% - 1 tool)
            var similarCount = count - recommendations.Count;
            if (similarCount > 0)
            {
                var similar = await GetSimilarToolsAsync(toolId, similarCount, addedToolIds);
                recommendations.AddRange(similar);
            }

            // If we don't have enough, fill with any available tools from same category
            if (recommendations.Count < count)
            {
                var remaining = count - recommendations.Count;
                var fillers = await GetAvailableToolsFromSameCategoryAsync(toolId, remaining, addedToolIds);
                recommendations.AddRange(fillers);
            }

            return recommendations.Take(count).ToList();
        }

        // ==================== Private Helper Methods ====================

        private async Task<List<int>> GetUserFavoriteCategoriesAsync(int userId)
        {
            // Get categories from user's completed orders (last 90 days)
            var thirtyDaysAgo = DateTime.UtcNow.AddDays(-90);

            var categories = await _context.Set<Order>()
                .Where(o => o.UserId == userId && o.CreatedAt >= thirtyDaysAgo)
                .SelectMany(o => o.OrderItems)
                .Include(oi => oi.Tool)
                .ThenInclude(t => t.Category)
                .Select(oi => oi.Tool.CategoryId)
                .GroupBy(c => c)
                .OrderByDescending(g => g.Count())
                .Take(3)
                .Select(g => g.Key)
                .ToListAsync();

            return categories;
        }

        private async Task<List<ToolResponse>> GetContentBasedRecommendationsAsync(
            int userId, 
            List<int> categoryIds, 
            int count, 
            HashSet<int> excludeToolIds)
        {
            // Get tools from user's favorite categories that they haven't ordered yet
            var userOrderedToolIds = await _context.Set<Order>()
                .Where(o => o.UserId == userId)
                .SelectMany(o => o.OrderItems)
                .Select(oi => oi.ToolId)
                .Distinct()
                .ToListAsync();

            var tools = await _context.Set<Tool>()
                .Include(t => t.Category)
                .Where(t => 
                    categoryIds.Contains(t.CategoryId) &&
                    t.IsAvailable &&
                    t.Quantity > 0 &&
                    !excludeToolIds.Contains(t.Id) &&
                    !userOrderedToolIds.Contains(t.Id))
                .OrderByDescending(t => t.DailyRate) // Prefer higher priced tools (better quality)
                .Take(count)
                .ToListAsync();

            foreach (var tool in tools)
            {
                excludeToolIds.Add(tool.Id);
            }

            return tools.Select(t => _mapper.Map<ToolResponse>(t)).ToList();
        }

        private async Task<List<ToolResponse>> GetPopularRecommendationsAsync(
            int count, 
            HashSet<int> excludeToolIds)
        {
            // Get most rented tools in last 30 days
            var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);

            var popularToolIds = await _context.Set<Order>()
                .Where(o => o.CreatedAt >= thirtyDaysAgo)
                .SelectMany(o => o.OrderItems)
                .GroupBy(oi => oi.ToolId)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .ToListAsync();

            var tools = await _context.Set<Tool>()
                .Include(t => t.Category)
                .Where(t => 
                    popularToolIds.Contains(t.Id) &&
                    t.IsAvailable &&
                    t.Quantity > 0 &&
                    !excludeToolIds.Contains(t.Id))
                .ToListAsync();

            // Order by popularity
            var orderedTools = tools
                .OrderBy(t => popularToolIds.IndexOf(t.Id))
                .Take(count)
                .ToList();

            foreach (var tool in orderedTools)
            {
                excludeToolIds.Add(tool.Id);
            }

            return orderedTools.Select(t => _mapper.Map<ToolResponse>(t)).ToList();
        }

        private async Task<List<ToolResponse>> GetTopRatedRecommendationsAsync(
            int count, 
            HashSet<int> excludeToolIds)
        {
            // Get tools with average rating >= 4.0
            var toolRatings = await _context.Set<Review>()
                .GroupBy(r => r.ToolId)
                .Select(g => new
                {
                    ToolId = g.Key,
                    AvgRating = g.Average(r => (double)r.Rating),
                    ReviewCount = g.Count()
                })
                .Where(x => x.AvgRating >= 4.0 && x.ReviewCount >= 2) // At least 2 reviews
                .OrderByDescending(x => x.AvgRating)
                .ThenByDescending(x => x.ReviewCount)
                .Select(x => x.ToolId)
                .ToListAsync();

            var tools = await _context.Set<Tool>()
                .Include(t => t.Category)
                .Where(t => 
                    toolRatings.Contains(t.Id) &&
                    t.IsAvailable &&
                    t.Quantity > 0 &&
                    !excludeToolIds.Contains(t.Id))
                .ToListAsync();

            // Order by rating
            var orderedTools = tools
                .OrderBy(t => toolRatings.IndexOf(t.Id))
                .Take(count)
                .ToList();

            foreach (var tool in orderedTools)
            {
                excludeToolIds.Add(tool.Id);
            }

            return orderedTools.Select(t => _mapper.Map<ToolResponse>(t)).ToList();
        }

        private async Task<List<ToolResponse>> GetFrequentlyBoughtTogetherAsync(
            int toolId, 
            int count, 
            HashSet<int> excludeToolIds)
        {
            // Find orders that contain this tool
            var ordersWithTool = await _context.Set<Order>()
                .Where(o => o.OrderItems.Any(oi => oi.ToolId == toolId))
                .Select(o => o.Id)
                .ToListAsync();

            if (!ordersWithTool.Any())
                return new List<ToolResponse>();

            // Find tools that were in the same orders
            var relatedToolIds = await _context.Set<OrderItem>()
                .Where(oi => ordersWithTool.Contains(oi.OrderId) && oi.ToolId != toolId)
                .GroupBy(oi => oi.ToolId)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .Take(count)
                .ToListAsync();

            var tools = await _context.Set<Tool>()
                .Include(t => t.Category)
                .Where(t => 
                    relatedToolIds.Contains(t.Id) &&
                    t.IsAvailable &&
                    t.Quantity > 0 &&
                    !excludeToolIds.Contains(t.Id))
                .ToListAsync();

            // Order by frequency
            var orderedTools = tools
                .OrderBy(t => relatedToolIds.IndexOf(t.Id))
                .ToList();

            foreach (var tool in orderedTools)
            {
                excludeToolIds.Add(tool.Id);
            }

            return orderedTools.Select(t => _mapper.Map<ToolResponse>(t)).ToList();
        }

        private async Task<List<ToolResponse>> GetSimilarToolsAsync(
            int toolId, 
            int count, 
            HashSet<int> excludeToolIds)
        {
            // Get tool's category
            var tool = await _context.Set<Tool>()
                .FirstOrDefaultAsync(t => t.Id == toolId);

            if (tool == null)
                return new List<ToolResponse>();

            // Get average rating of current tool
            var currentToolRating = await _context.Set<Review>()
                .Where(r => r.ToolId == toolId)
                .Select(r => (double?)r.Rating)
                .AverageAsync() ?? 0;

            // Get tools from same category with similar rating (±1.0)
            var similarTools = await _context.Set<Tool>()
                .Include(t => t.Category)
                .Where(t => 
                    t.CategoryId == tool.CategoryId &&
                    t.Id != toolId &&
                    t.IsAvailable &&
                    t.Quantity > 0 &&
                    !excludeToolIds.Contains(t.Id))
                .ToListAsync();

            // Calculate ratings for each tool
            var toolsWithRatings = new List<(Tool tool, double rating)>();
            foreach (var t in similarTools)
            {
                var rating = await _context.Set<Review>()
                    .Where(r => r.ToolId == t.Id)
                    .Select(r => (double?)r.Rating)
                    .AverageAsync() ?? 0;

                if (rating == 0 || Math.Abs(rating - currentToolRating) <= 1.0)
                {
                    toolsWithRatings.Add((t, rating));
                }
            }

            var selected = toolsWithRatings
                .OrderByDescending(x => x.rating)
                .Take(count)
                .Select(x => x.tool)
                .ToList();

            foreach (var t in selected)
            {
                excludeToolIds.Add(t.Id);
            }

            return selected.Select(t => _mapper.Map<ToolResponse>(t)).ToList();
        }

        private async Task<List<ToolResponse>> GetAvailableToolsAsync(
            int count, 
            HashSet<int> excludeToolIds)
        {
            var tools = await _context.Set<Tool>()
                .Include(t => t.Category)
                .Where(t => 
                    t.IsAvailable &&
                    t.Quantity > 0 &&
                    !excludeToolIds.Contains(t.Id))
                .OrderByDescending(t => t.Id) // Order by ID (newest first)
                .Take(count)
                .ToListAsync();

            return tools.Select(t => _mapper.Map<ToolResponse>(t)).ToList();
        }

        private async Task<List<ToolResponse>> GetAvailableToolsFromSameCategoryAsync(
            int toolId, 
            int count, 
            HashSet<int> excludeToolIds)
        {
            var tool = await _context.Set<Tool>()
                .FirstOrDefaultAsync(t => t.Id == toolId);

            if (tool == null)
                return new List<ToolResponse>();

            var tools = await _context.Set<Tool>()
                .Include(t => t.Category)
                .Where(t => 
                    t.CategoryId == tool.CategoryId &&
                    t.Id != toolId &&
                    t.IsAvailable &&
                    t.Quantity > 0 &&
                    !excludeToolIds.Contains(t.Id))
                .Take(count)
                .ToListAsync();

            return tools.Select(t => _mapper.Map<ToolResponse>(t)).ToList();
        }
    }
}

