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
        private readonly ISettingsService _settingsService;
        private readonly MLPredictionService _mlPredictionService;

        public RecommendationService(
            ApplicationDbContext context, 
            IMapper mapper, 
            ISettingsService settingsService,
            MLPredictionService mlPredictionService)
        {
            _context = context;
            _mapper = mapper;
            _settingsService = settingsService;
            _mlPredictionService = mlPredictionService;
        }

        // Gets personalized recommendations for home screen using selected engine (Rule-Based, ML, or Hybrid)
        public async Task<List<ToolResponse>> GetHomeRecommendationsAsync(int userId, int count = 6)
        {
            // Get settings from database
            var settings = await _settingsService.GetRecommendationSettingsAsync();

            // Route to appropriate recommendation engine
            switch (settings.Engine)
            {
                case RecommendationEngine.MachineLearning:
                    return await GetHomeRecommendationsMLAsync(userId, count);

                case RecommendationEngine.Hybrid:
                    return await GetHomeRecommendationsHybridAsync(userId, count);

                case RecommendationEngine.RuleBased:
                default:
                    return await GetHomeRecommendationsRuleBasedAsync(userId, count);
            }
        }

        // Gets home recommendations using pure Machine Learning predictions
        private async Task<List<ToolResponse>> GetHomeRecommendationsMLAsync(int userId, int count = 6)
        {
            try
            {
                var toolIds = await _mlPredictionService.GetMLRecommendationsAsync(userId, count);
                
                if (!toolIds.Any())
                    return new List<ToolResponse>();

                var tools = await _context.Set<Tool>()
                    .Include(t => t.Category)
                    .Where(t => toolIds.Contains(t.Id))
                    .ToListAsync();

                // Order by the ML prediction order
                var orderedTools = toolIds
                    .Select(id => tools.FirstOrDefault(t => t.Id == id))
                    .Where(t => t != null)
                    .Take(count)
                    .ToList();

                return orderedTools.Select(t => _mapper.Map<ToolResponse>(t!)).ToList();
            }
            catch (Exception)
            {
                // If ML fails, return empty list
                return new List<ToolResponse>();
            }
        }

        // Gets home recommendations using Hybrid approach (ML first, falls back to Rule-Based if needed)
        private async Task<List<ToolResponse>> GetHomeRecommendationsHybridAsync(int userId, int count = 6)
        {
            // Try ML first
            var mlRecommendations = await GetHomeRecommendationsMLAsync(userId, count);

            // If ML returned enough recommendations, use them
            if (mlRecommendations.Count >= count / 2)
            {
                // If ML gave us some but not enough, fill the rest with rule-based
                if (mlRecommendations.Count < count)
                {
                    var addedToolIds = new HashSet<int>(mlRecommendations.Select(r => r.Id));
                    var remaining = count - mlRecommendations.Count;
                    var ruleBasedRecommendations = await GetHomeRecommendationsRuleBasedAsync(userId, remaining, addedToolIds);
                    mlRecommendations.AddRange(ruleBasedRecommendations.Take(remaining));
                }
                return mlRecommendations;
            }

            // ML didn't work or returned too few results, fall back to rule-based
            return await GetHomeRecommendationsRuleBasedAsync(userId, count);
        }

        // Gets home recommendations using Rule-Based approach with weighted algorithms
        private async Task<List<ToolResponse>> GetHomeRecommendationsRuleBasedAsync(int userId, int count = 6, HashSet<int>? excludeToolIds = null)
        {
            var recommendations = new List<ToolResponse>();
            var addedToolIds = excludeToolIds ?? new HashSet<int>();

            // Get settings from database
            var settings = await _settingsService.GetRecommendationSettingsAsync();
            var homePopularWeight = settings.HomePopularWeight / 100.0;
            var homeContentBasedWeight = settings.HomeContentBasedWeight / 100.0;
            var homeTopRatedWeight = settings.HomeTopRatedWeight / 100.0;

            // 1. Get user's favorite categories from their orders (Content-based)
            var userFavoriteCategories = await GetUserFavoriteCategoriesAsync(userId);
            var contentBasedCount = (int)(count * homeContentBasedWeight);

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

            // 2. Get popular/trending tools
            var popularCount = (int)(count * homePopularWeight);
            if (popularCount > 0)
            {
                var popular = await GetPopularRecommendationsAsync(popularCount, addedToolIds);
                recommendations.AddRange(popular);
            }

            // 3. Get top rated tools
            var topRatedCount = (int)(count * homeTopRatedWeight);
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

            // If still no recommendations (user has no history or no data in system), return default recommendations
            // This ensures we always return something if there are tools available
            if (recommendations.Count == 0)
            {
                var defaultRecommendations = await GetDefaultRecommendationsAsync(count);
                // Final safety check: if default also returns empty, try any available tools without exclusions
                if (defaultRecommendations.Count == 0)
                {
                    defaultRecommendations = await GetAvailableToolsAsync(count, new HashSet<int>());
                }
                // If we got something from defaults, return it
                if (defaultRecommendations.Count > 0)
                {
                    return defaultRecommendations;
                }
                // Last resort: return empty list (no tools in system)
            }

            return recommendations.Count > 0 ? recommendations.Take(count).ToList() : new List<ToolResponse>();
        }

        // Gets cart recommendations when user adds item to cart using selected engine
        public async Task<List<ToolResponse>> GetCartRecommendationsAsync(int toolId, int count = 3)
        {
            // Get settings from database
            var settings = await _settingsService.GetRecommendationSettingsAsync();

            // Route to appropriate recommendation engine
            switch (settings.Engine)
            {
                case RecommendationEngine.MachineLearning:
                    return await GetCartRecommendationsMLAsync(toolId, count);

                case RecommendationEngine.Hybrid:
                    return await GetCartRecommendationsHybridAsync(toolId, count);

                case RecommendationEngine.RuleBased:
                default:
                    return await GetCartRecommendationsRuleBasedAsync(toolId, count);
            }
        }

        // Gets cart recommendations using pure Machine Learning predictions
        private async Task<List<ToolResponse>> GetCartRecommendationsMLAsync(int toolId, int count = 3)
        {
            try
            {
                var recommendedToolIds = await _mlPredictionService.GetMLCartRecommendationsAsync(toolId, count);
                
                if (!recommendedToolIds.Any())
                    return new List<ToolResponse>();

                var tools = await _context.Set<Tool>()
                    .Include(t => t.Category)
                    .Where(t => recommendedToolIds.Contains(t.Id))
                    .ToListAsync();

                // Order by the ML prediction order
                var orderedTools = recommendedToolIds
                    .Select(id => tools.FirstOrDefault(t => t.Id == id))
                    .Where(t => t != null)
                    .Take(count)
                    .ToList();

                return orderedTools.Select(t => _mapper.Map<ToolResponse>(t!)).ToList();
            }
            catch (Exception)
            {
                return new List<ToolResponse>();
            }
        }

        // Gets cart recommendations using Hybrid approach (ML first, falls back to Rule-Based if needed)
        private async Task<List<ToolResponse>> GetCartRecommendationsHybridAsync(int toolId, int count = 3)
        {
            // Try ML first
            var mlRecommendations = await GetCartRecommendationsMLAsync(toolId, count);

            // If ML returned some recommendations, use them
            if (mlRecommendations.Count >= 1)
            {
                // If ML gave us some but not enough, fill the rest with rule-based
                if (mlRecommendations.Count < count)
                {
                    var addedToolIds = new HashSet<int>(mlRecommendations.Select(r => r.Id)) { toolId };
                    var remaining = count - mlRecommendations.Count;
                    var ruleBasedRecommendations = await GetCartRecommendationsRuleBasedAsync(toolId, remaining, addedToolIds);
                    mlRecommendations.AddRange(ruleBasedRecommendations.Take(remaining));
                }
                return mlRecommendations;
            }

            // ML didn't work, fall back to rule-based
            return await GetCartRecommendationsRuleBasedAsync(toolId, count);
        }

        // Gets cart recommendations using Rule-Based approach with frequently bought together logic
        private async Task<List<ToolResponse>> GetCartRecommendationsRuleBasedAsync(int toolId, int count = 3, HashSet<int>? excludeToolIds = null)
        {
            var recommendations = new List<ToolResponse>();
            var addedToolIds = excludeToolIds ?? new HashSet<int> { toolId };

            // Get settings from database
            var settings = await _settingsService.GetRecommendationSettingsAsync();
            var cartFrequentlyBoughtWeight = settings.CartFrequentlyBoughtWeight / 100.0;
            var cartSimilarToolsWeight = settings.CartSimilarToolsWeight / 100.0;

            // 1. Frequently Bought Together
            var frequentlyBoughtCount = (int)(count * cartFrequentlyBoughtWeight);
            var frequentlyBought = await GetFrequentlyBoughtTogetherAsync(toolId, frequentlyBoughtCount, addedToolIds);
            recommendations.AddRange(frequentlyBought);

            // 2. Similar Tools from same category
            var similarCount = (int)(count * cartSimilarToolsWeight);
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

            // If still not enough, fill with any available tools from any category
            if (recommendations.Count < count)
            {
                var remaining = count - recommendations.Count;
                var fillers = await GetAvailableToolsAsync(remaining, addedToolIds);
                recommendations.AddRange(fillers);
            }

            return recommendations.Take(count).ToList();
        }

        // Gets user's favorite categories based on order history
        private async Task<List<int>> GetUserFavoriteCategoriesAsync(int userId)
        {
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

        // Gets default recommendations when user has no history
        private async Task<List<ToolResponse>> GetDefaultRecommendationsAsync(int count)
        {
            var recommendations = new List<ToolResponse>();
            var addedToolIds = new HashSet<int>();

            // Try to get popular tools first (40%)
            var popularCount = (int)(count * 0.4);
            if (popularCount > 0)
            {
                var popular = await GetPopularRecommendationsAsync(popularCount, addedToolIds);
                recommendations.AddRange(popular);
            }

            // Fill with top rated (30%)
            if (recommendations.Count < count)
            {
                var remaining = count - recommendations.Count;
                var topRated = await GetTopRatedRecommendationsAsync(remaining, addedToolIds);
                recommendations.AddRange(topRated);
            }

            // If still not enough (or both popular and top rated returned empty), get any available tools
            // This ensures we always return something if there are any tools in the system
            if (recommendations.Count < count)
            {
                var remaining = count - recommendations.Count;
                var fillers = await GetAvailableToolsAsync(remaining, addedToolIds);
                recommendations.AddRange(fillers);
            }

            // Final fallback: if we still have nothing, try without exclusions
            if (recommendations.Count == 0)
            {
                recommendations = await GetAvailableToolsAsync(count, new HashSet<int>());
            }

            return recommendations.Take(count).ToList();
        }
    }
}

