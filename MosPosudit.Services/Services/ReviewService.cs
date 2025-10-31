using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.Review;
using MosPosudit.Model.Responses.Review;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class ReviewService : BaseCrudService<Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest, ReviewPatchRequest>, IReviewService
    {
        public ReviewService(ApplicationDbContext context) : base(context)
        {
        }

        public override async Task<IEnumerable<Review>> Get(ReviewSearchObject? search = null)
        {
            var query = _dbSet
                .Include(r => r.User)
                .Include(r => r.Tool)
                .Include(r => r.Rental)
                .AsQueryable();

            if (search != null)
            {
                if (search.ToolId.HasValue)
                    query = query.Where(r => r.ToolId == search.ToolId.Value);

                if (search.UserId.HasValue)
                    query = query.Where(r => r.UserId == search.UserId.Value);

                if (search.RentalId.HasValue)
                    query = query.Where(r => r.RentalId == search.RentalId.Value);

                if (search.Rating.HasValue)
                    query = query.Where(r => r.Rating == search.Rating.Value);

                if (search.MinRating.HasValue)
                    query = query.Where(r => r.Rating >= search.MinRating.Value);

                if (search.MaxRating.HasValue)
                    query = query.Where(r => r.Rating <= search.MaxRating.Value);
            }

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                            .Take(search.PageSize.Value);
            }

            return await query.ToListAsync();
        }

        public override async Task<Review> GetById(int id)
        {
            if (id <= 0)
                throw new ValidationException("Invalid review ID");

            var review = await _dbSet
                .Include(r => r.User)
                .Include(r => r.Tool)
                .Include(r => r.Rental)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (review == null)
                throw new NotFoundException("Review not found");

            return review;
        }

        public override async Task<Review> Insert(ReviewInsertRequest insert)
        {
            if (insert == null)
                throw new ValidationException("Invalid request");

            // Validate rating
            if (insert.Rating < 1 || insert.Rating > 5)
                throw new ValidationException("Rating must be between 1 and 5");

            // Verify tool exists
            var tool = await _context.Tools.FindAsync(insert.ToolId);
            if (tool == null)
                throw new NotFoundException("Tool not found");

            // Verify rental exists and belongs to user
            var rental = await _context.Rentals
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == insert.RentalId);
            
            if (rental == null)
                throw new NotFoundException("Rental not found");

            if (rental.UserId != insert.UserId)
                throw new ValidationException("Rental does not belong to this user");

            // Check if user already reviewed this rental
            var existingReview = await _dbSet
                .FirstOrDefaultAsync(r => r.RentalId == insert.RentalId && r.UserId == insert.UserId);

            if (existingReview != null)
                throw new ValidationException("You have already reviewed this rental");

            var entity = MapToEntity(insert);
            await _dbSet.AddAsync(entity);
            await _context.SaveChangesAsync();

            // Reload with includes
            return await GetById(entity.Id);
        }

        public async Task<IEnumerable<ReviewResponse>> GetAsResponse(ReviewSearchObject? search = null)
        {
            var entities = await Get(search);
            return entities.Select(MapToResponse);
        }

        public async Task<ReviewResponse> GetByIdAsResponse(int id)
        {
            var entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<ReviewResponse> InsertAsResponse(ReviewInsertRequest insert)
        {
            var entity = await Insert(insert);
            return MapToResponse(entity);
        }

        public async Task<ReviewResponse> UpdateAsResponse(int id, ReviewUpdateRequest update)
        {
            var entity = await Update(id, update);
            return MapToResponse(entity);
        }

        public async Task<ReviewResponse> PatchAsResponse(int id, ReviewPatchRequest patch)
        {
            var entity = await Patch(id, patch);
            return MapToResponse(entity);
        }

        public async Task<ReviewResponse> DeleteAsResponse(int id)
        {
            var entity = await Delete(id);
            return MapToResponse(entity);
        }

        public async Task<IEnumerable<ReviewResponse>> GetByToolIdAsResponse(int toolId)
        {
            var search = new ReviewSearchObject { ToolId = toolId };
            return await GetAsResponse(search);
        }

        public ReviewResponse MapToResponse(Review entity)
        {
            return new ReviewResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UserName = entity.User != null ? $"{entity.User.FirstName} {entity.User.LastName}".Trim() : null,
                ToolId = entity.ToolId,
                ToolName = entity.Tool?.Name,
                RentalId = entity.RentalId,
                Rating = entity.Rating,
                Comment = entity.Comment,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt
            };
        }

        protected override Review MapToEntity(ReviewInsertRequest insert)
        {
            return new Review
            {
                UserId = insert.UserId,
                ToolId = insert.ToolId,
                RentalId = insert.RentalId,
                Rating = insert.Rating,
                Comment = insert.Comment,
                CreatedAt = DateTime.UtcNow
            };
        }

        protected override void MapToEntity(ReviewUpdateRequest update, Review entity)
        {
            entity.Rating = update.Rating;
            if (update.Comment != null)
                entity.Comment = update.Comment;
            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override void MapToEntity(ReviewPatchRequest patch, Review entity)
        {
            if (patch.Rating.HasValue)
                entity.Rating = patch.Rating.Value;
            if (patch.Comment != null)
                entity.Comment = patch.Comment;
            entity.UpdatedAt = DateTime.UtcNow;
        }
    }
}

