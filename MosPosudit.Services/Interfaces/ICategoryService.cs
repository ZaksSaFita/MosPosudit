using MosPosudit.Model.Requests.Category;
using MosPosudit.Model.Responses.Category;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface ICategoryService : ICrudService<CategoryResponse, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest>
    {
    }
}

