using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.UserFavorite;
using MosPosudit.Model.Responses.UserFavorite;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class UserFavoriteService : BaseCrudService<UserFavoriteResponse, UserFavoriteSearchObject, UserFavorite, UserFavoriteInsertRequest, UserFavoriteUpdateRequest>, IUserFavoriteService
    {
        public UserFavoriteService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<UserFavorite> ApplyFilter(IQueryable<UserFavorite> query, UserFavoriteSearchObject search)
        {
            query = query.Include(uf => uf.Tool);

            if (search.UserId.HasValue)
                query = query.Where(uf => uf.UserId == search.UserId.Value);

            if (search.ToolId.HasValue)
                query = query.Where(uf => uf.ToolId == search.ToolId.Value);

            return query.OrderByDescending(uf => uf.CreatedAt);
        }

        public override async Task<UserFavoriteResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<UserFavorite>()
                .Include(uf => uf.Tool)
                .FirstOrDefaultAsync(uf => uf.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        public override async Task<UserFavoriteResponse> CreateAsync(UserFavoriteInsertRequest request)
        {
            if (request == null)
                throw new ValidationException("Invalid request");

            // Verify tool exists
            var tool = await _context.Tools.FindAsync(request.ToolId);
            if (tool == null)
                throw new NotFoundException("Tool not found");

            // Check if already in favorites
            var existing = await _context.Set<UserFavorite>()
                .FirstOrDefaultAsync(uf => uf.UserId == request.UserId && uf.ToolId == request.ToolId);

            if (existing != null)
                throw new ValidationException("Tool is already in favorites");

            var entity = _mapper.Map<UserFavorite>(request);
            entity.CreatedAt = DateTime.UtcNow;

            await _context.Set<UserFavorite>().AddAsync(entity);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(entity.Id) ?? throw new Exception("Failed to retrieve created favorite");
        }

        public override async Task<UserFavoriteResponse?> UpdateAsync(int id, UserFavoriteUpdateRequest request)
        {
            // UserFavorite doesn't support update operations
            throw new ValidationException("Update operation is not supported for UserFavorite");
        }

        public async Task<bool> DeleteByUserAndTool(int userId, int toolId)
        {
            var entity = await _context.Set<UserFavorite>()
                .FirstOrDefaultAsync(uf => uf.UserId == userId && uf.ToolId == toolId);

            if (entity == null)
                return false;

            _context.Set<UserFavorite>().Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> IsFavorite(int userId, int toolId)
        {
            return await _context.Set<UserFavorite>()
                .AnyAsync(uf => uf.UserId == userId && uf.ToolId == toolId);
        }

        protected override UserFavoriteResponse MapToResponse(UserFavorite entity)
        {
            var response = _mapper.Map<UserFavoriteResponse>(entity);
            // Map nested properties
            response.ToolName = entity.Tool?.Name;
            response.ToolDescription = entity.Tool?.Description;
            response.ToolDailyRate = entity.Tool?.DailyRate ?? 0;
            response.ToolImageBase64 = entity.Tool?.ImageBase64;
            return response;
        }
    }
}

