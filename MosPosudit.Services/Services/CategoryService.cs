using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Requests.Category;
using MosPosudit.Model.Responses.Category;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class CategoryService : BaseCrudService<CategoryResponse, CategorySearchObject, Category, CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
    {
        public CategoryService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(x => x.Name != null && x.Name.Contains(search.Name));

            return query;
        }
    }
}
