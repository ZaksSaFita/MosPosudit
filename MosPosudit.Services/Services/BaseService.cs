using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Responses;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public abstract class BaseService<T, TSearch, TEntity> : IService<T, TSearch> 
        where T : class 
        where TSearch : BaseSearchObject 
        where TEntity : class
    {
        protected readonly ApplicationDbContext _context;
        protected readonly IMapper _mapper;

        public BaseService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
            _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
        }

        public virtual async Task<PagedResult<T>> GetAsync(TSearch search)
        {
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);
            
            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue && search.PageSize.HasValue)
                {
                    query = query.Skip((search.Page.Value - 1) * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync();
            return new PagedResult<T>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            return query;
        }

        public virtual async Task<T?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected virtual T MapToResponse(TEntity entity)
        {
            return _mapper.Map<T>(entity);
        }
    }
}

