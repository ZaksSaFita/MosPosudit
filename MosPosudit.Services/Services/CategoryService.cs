using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.Category;
using MosPosudit.Model.Responses.Category;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class CategoryService : BaseCrudService<Category, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest, CategoryPatchRequest>, ICategoryService
    {
        public CategoryService(ApplicationDbContext context) : base(context)
        {
        }

        public override async Task<IEnumerable<Category>> Get(CategorySearchObject? search = null)
        {
            var query = _dbSet.AsQueryable();

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                    query = query.Where(x => x.Name != null && x.Name.Contains(search.Name));
            }

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                            .Take(search.PageSize.Value);
            }

            return await query.ToListAsync();
        }

        public override async Task<Category> GetById(int id)
        {
            if (id <= 0)
                throw new ValidationException("Invalid category ID");

            var category = await _dbSet.FirstOrDefaultAsync(c => c.Id == id);
            if (category == null)
                throw new NotFoundException("Category not found");

            return category;
        }

        public async Task<IEnumerable<CategoryResponse>> GetAsResponse(CategorySearchObject? search = null)
        {
            var entities = await Get(search);
            return entities.Select(MapToResponse);
        }

        public async Task<CategoryResponse> GetByIdAsResponse(int id)
        {
            var entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<CategoryResponse> InsertAsResponse(CategoryInsertRequest insert)
        {
            var entity = await Insert(insert);
            return MapToResponse(entity);
        }

        public async Task<CategoryResponse> UpdateAsResponse(int id, CategoryUpdateRequest update)
        {
            var entity = await Update(id, update);
            return MapToResponse(entity);
        }

        public async Task<CategoryResponse> PatchAsResponse(int id, CategoryPatchRequest patch)
        {
            var entity = await Patch(id, patch);
            return MapToResponse(entity);
        }

        public async Task<CategoryResponse> DeleteAsResponse(int id)
        {
            var entity = await Delete(id);
            return MapToResponse(entity);
        }

        public CategoryResponse MapToResponse(Category entity)
        {
            return new CategoryResponse
            {
                Id = entity.Id,
                Name = entity.Name,
                Description = entity.Description,
                ImageBase64 = entity.ImageBase64
            };
        }

        protected override Category MapToEntity(CategoryInsertRequest insert)
        {
            return new Category
            {
                Name = insert.Name,
                Description = insert.Description,
                ImageBase64 = insert.ImageBase64
            };
        }

        protected override void MapToEntity(CategoryUpdateRequest update, Category entity)
        {
            if (update.Name != null)
                entity.Name = update.Name;
            if (update.Description != null)
                entity.Description = update.Description;
            if (update.ImageBase64 != null)
                entity.ImageBase64 = update.ImageBase64;
        }

        protected override void MapToEntity(CategoryPatchRequest patch, Category entity)
        {
            if (patch.Name != null)
                entity.Name = patch.Name;
            if (patch.Description != null)
                entity.Description = patch.Description;
            if (patch.ImageBase64 != null)
                entity.ImageBase64 = patch.ImageBase64;
        }
    }
}

