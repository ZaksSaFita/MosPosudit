using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.Tool;
using MosPosudit.Model.Responses.Tool;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class ToolService : BaseCrudService<Tool, ToolSearchObject, ToolInsertRequest, ToolUpdateRequest, ToolPatchRequest>, IToolService
    {
        public ToolService(ApplicationDbContext context) : base(context)
        {
        }

        public override async Task<IEnumerable<Tool>> Get(ToolSearchObject? search = null)
        {
            var query = _dbSet.Include(t => t.Category).AsQueryable();

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                    query = query.Where(x => x.Name != null && x.Name.Contains(search.Name));

                if (search.CategoryId.HasValue)
                    query = query.Where(x => x.CategoryId == search.CategoryId.Value);

                if (search.IsAvailable.HasValue)
                    query = query.Where(x => x.IsAvailable == search.IsAvailable.Value);
            }

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                            .Take(search.PageSize.Value);
            }

            return await query.ToListAsync();
        }

        public override async Task<Tool> GetById(int id)
        {
            if (id <= 0)
                throw new ValidationException("Invalid tool ID");

            var tool = await _dbSet.Include(t => t.Category).FirstOrDefaultAsync(t => t.Id == id);
            if (tool == null)
                throw new NotFoundException("Tool not found");

            return tool;
        }

        public async Task<IEnumerable<ToolResponse>> GetAsResponse(ToolSearchObject? search = null)
        {
            var entities = await Get(search);
            return entities.Select(MapToResponse);
        }

        public async Task<ToolResponse> GetByIdAsResponse(int id)
        {
            var entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<ToolResponse> InsertAsResponse(ToolInsertRequest insert)
        {
            var entity = await Insert(insert);
            // Reload with Category for MapToResponse
            entity = await GetById(entity.Id);
            return MapToResponse(entity);
        }

        public async Task<ToolResponse> UpdateAsResponse(int id, ToolUpdateRequest update)
        {
            var entity = await Update(id, update);
            // Reload with Category for MapToResponse
            entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<ToolResponse> PatchAsResponse(int id, ToolPatchRequest patch)
        {
            var entity = await Patch(id, patch);
            // Reload with Category for MapToResponse
            entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<ToolResponse> DeleteAsResponse(int id)
        {
            var entity = await GetById(id);
            var response = MapToResponse(entity);
            await Delete(id);
            return response;
        }

        public ToolResponse MapToResponse(Tool entity)
        {
            return new ToolResponse
            {
                Id = entity.Id,
                Name = entity.Name,
                Description = entity.Description,
                CategoryId = entity.CategoryId,
                CategoryName = entity.Category?.Name,
                DailyRate = entity.DailyRate,
                Quantity = entity.Quantity,
                IsAvailable = entity.IsAvailable,
                DepositAmount = entity.DepositAmount,
                ImageBase64 = entity.ImageBase64
            };
        }

        protected override Tool MapToEntity(ToolInsertRequest insert)
        {
            return new Tool
            {
                Name = insert.Name,
                Description = insert.Description,
                CategoryId = insert.CategoryId,
                DailyRate = insert.DailyRate,
                Quantity = insert.Quantity,
                DepositAmount = insert.DepositAmount,
                IsAvailable = insert.IsAvailable,
                ImageBase64 = insert.ImageBase64
            };
        }

        protected override void MapToEntity(ToolUpdateRequest update, Tool entity)
        {
            if (update.Name != null)
                entity.Name = update.Name;
            if (update.Description != null)
                entity.Description = update.Description;
            if (update.CategoryId.HasValue)
                entity.CategoryId = update.CategoryId.Value;
            if (update.DailyRate.HasValue)
                entity.DailyRate = update.DailyRate.Value;
            if (update.Quantity.HasValue)
                entity.Quantity = update.Quantity.Value;
            if (update.DepositAmount.HasValue)
                entity.DepositAmount = update.DepositAmount.Value;
            if (update.IsAvailable.HasValue)
                entity.IsAvailable = update.IsAvailable.Value;
            if (update.ImageBase64 != null)
                entity.ImageBase64 = update.ImageBase64;
        }

        protected override void MapToEntity(ToolPatchRequest patch, Tool entity)
        {
            if (patch.Name != null)
                entity.Name = patch.Name;
            if (patch.Description != null)
                entity.Description = patch.Description;
            if (patch.CategoryId.HasValue)
                entity.CategoryId = patch.CategoryId.Value;
            if (patch.DailyRate.HasValue)
                entity.DailyRate = patch.DailyRate.Value;
            if (patch.Quantity.HasValue)
                entity.Quantity = patch.Quantity.Value;
            if (patch.DepositAmount != null)
                entity.DepositAmount = patch.DepositAmount.Value;
            if (patch.IsAvailable.HasValue)
                entity.IsAvailable = patch.IsAvailable.Value;
            if (patch.ImageBase64 != null)
                entity.ImageBase64 = patch.ImageBase64;
        }
    }
}

