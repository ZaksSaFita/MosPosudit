using MosPosudit.Model.Requests.Category;
using MosPosudit.Model.Responses.Category;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface ICategoryService : ICrudService<Category, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest, CategoryPatchRequest>
    {
        Task<IEnumerable<CategoryResponse>> GetAsResponse(CategorySearchObject? search = null);
        Task<CategoryResponse> GetByIdAsResponse(int id);
        Task<CategoryResponse> InsertAsResponse(CategoryInsertRequest insert);
        Task<CategoryResponse> UpdateAsResponse(int id, CategoryUpdateRequest update);
        Task<CategoryResponse> PatchAsResponse(int id, CategoryPatchRequest patch);
        Task<CategoryResponse> DeleteAsResponse(int id);
        CategoryResponse MapToResponse(Category entity);
    }
}

