using MošPosudit.Model.SearchObjects;

namespace MošPosudit.Services.Interfaces
{
    public interface ICrudService<T, TSearch, TInsert, TUpdate, TPatch> where T : class where TSearch : BaseSearchObject
    {
        Task<IEnumerable<T>> Get(TSearch? search = null);
        Task<T> GetById(int id);
        Task<T> Insert(TInsert insert);
        Task<T> Update(int id, TUpdate update);
        Task<T> Patch(int id, TPatch patch);
        Task<T> Delete(int id);
    }
} 