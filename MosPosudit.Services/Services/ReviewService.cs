using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.Review;
using MosPosudit.Model.Responses.Review;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class ReviewService : BaseCrudService<ReviewResponse, ReviewSearchObject, Review, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        public ReviewService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            query = query
                .Include(r => r.User)
                .Include(r => r.Tool);

            if (search.ToolId.HasValue)
                query = query.Where(r => r.ToolId == search.ToolId.Value);

            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);

            if (search.Rating.HasValue)
                query = query.Where(r => r.Rating == search.Rating.Value);

            if (search.MinRating.HasValue)
                query = query.Where(r => r.Rating >= search.MinRating.Value);

            if (search.MaxRating.HasValue)
                query = query.Where(r => r.Rating <= search.MaxRating.Value);

            return query;
        }

        public override async Task<ReviewResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<Review>()
                .Include(r => r.User)
                .Include(r => r.Tool)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        public override async Task<ReviewResponse> CreateAsync(ReviewInsertRequest request)
        {
            // Validate rating
            if (request.Rating < 1 || request.Rating > 5)
                throw new ValidationException("Rating must be between 1 and 5");

            // Verify tool exists
            var tool = await _context.Tools.FindAsync(request.ToolId);
            if (tool == null)
                throw new NotFoundException("Tool not found");

            // Check if user already reviewed this tool
            var existingReview = await _context.Set<Review>()
                .FirstOrDefaultAsync(r => r.ToolId == request.ToolId && r.UserId == request.UserId);

            if (existingReview != null)
                throw new ValidationException("You have already reviewed this tool");

            var entity = _mapper.Map<Review>(request);
            entity.CreatedAt = DateTime.UtcNow;

            _context.Set<Review>().Add(entity);
            await _context.SaveChangesAsync();

            // Reload with includes
            return await GetByIdAsync(entity.Id) ?? throw new Exception("Failed to retrieve created review");
        }

        protected override async Task BeforeUpdate(Review entity, ReviewUpdateRequest request)
        {
            entity.UpdatedAt = DateTime.UtcNow;
            await Task.CompletedTask;
        }

        public async Task<IEnumerable<ReviewResponse>> GetByToolIdAsResponse(int toolId)
        {
            var search = new ReviewSearchObject { ToolId = toolId };
            var result = await GetAsync(search);
            return result.Items;
        }

        protected override ReviewResponse MapToResponse(Review entity)
        {
            var response = _mapper.Map<ReviewResponse>(entity);
            // Map nested properties: User.Username -> UserName, Tool.Name -> ToolName
            response.UserName = entity.User?.Username;
            response.ToolName = entity.Tool?.Name;
            return response;
        }
    }
}
