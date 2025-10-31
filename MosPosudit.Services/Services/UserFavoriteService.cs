using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.UserFavorite;
using MosPosudit.Model.Responses.UserFavorite;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class UserFavoriteService : IUserFavoriteService
    {
        private readonly ApplicationDbContext _context;
        private readonly DbSet<UserFavorite> _dbSet;

        public UserFavoriteService(ApplicationDbContext context)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
            _dbSet = context.Set<UserFavorite>();
        }

        public async Task<IEnumerable<UserFavoriteResponse>> GetAsResponse(UserFavoriteSearchObject? search = null)
        {
            var query = _dbSet
                .Include(uf => uf.Tool)
                .AsQueryable();

            if (search != null)
            {
                if (search.UserId.HasValue)
                    query = query.Where(uf => uf.UserId == search.UserId.Value);

                if (search.ToolId.HasValue)
                    query = query.Where(uf => uf.ToolId == search.ToolId.Value);
            }

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                            .Take(search.PageSize.Value);
            }

            var entities = await query.OrderByDescending(uf => uf.CreatedAt).ToListAsync();
            return entities.Select(MapToResponse);
        }

        public async Task<UserFavoriteResponse> GetByIdAsResponse(int id)
        {
            if (id <= 0)
                throw new ValidationException("Invalid favorite ID");

            var entity = await _dbSet
                .Include(uf => uf.Tool)
                .FirstOrDefaultAsync(uf => uf.Id == id);

            if (entity == null)
                throw new NotFoundException("Favorite not found");

            return MapToResponse(entity);
        }

        public async Task<UserFavoriteResponse> InsertAsResponse(UserFavoriteInsertRequest insert)
        {
            if (insert == null)
                throw new ValidationException("Invalid request");

            // Verify tool exists
            var tool = await _context.Tools.FindAsync(insert.ToolId);
            if (tool == null)
                throw new NotFoundException("Tool not found");

            // Check if already in favorites
            var existing = await _dbSet
                .FirstOrDefaultAsync(uf => uf.UserId == insert.UserId && uf.ToolId == insert.ToolId);

            if (existing != null)
                throw new ValidationException("Tool is already in favorites");

            var entity = new UserFavorite
            {
                UserId = insert.UserId,
                ToolId = insert.ToolId,
                CreatedAt = DateTime.UtcNow
            };

            await _dbSet.AddAsync(entity);
            await _context.SaveChangesAsync();

            // Reload with includes
            var reloaded = await _dbSet
                .Include(uf => uf.Tool)
                .FirstOrDefaultAsync(uf => uf.Id == entity.Id);

            return MapToResponse(reloaded!);
        }

        public async Task<bool> DeleteByUserAndTool(int userId, int toolId)
        {
            var entity = await _dbSet
                .FirstOrDefaultAsync(uf => uf.UserId == userId && uf.ToolId == toolId);

            if (entity == null)
                return false;

            _dbSet.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> IsFavorite(int userId, int toolId)
        {
            return await _dbSet
                .AnyAsync(uf => uf.UserId == userId && uf.ToolId == toolId);
        }

        private UserFavoriteResponse MapToResponse(UserFavorite entity)
        {
            return new UserFavoriteResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                ToolId = entity.ToolId,
                ToolName = entity.Tool?.Name,
                ToolDescription = entity.Tool?.Description,
                ToolDailyRate = entity.Tool?.DailyRate,
                ToolImageBase64 = entity.Tool?.ImageBase64,
                CreatedAt = entity.CreatedAt
            };
        }
    }
}

