using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public abstract class BaseCrudService<T, TSearch, TEntity, TInsert, TUpdate> 
        : BaseService<T, TSearch, TEntity>, ICrudService<T, TSearch, TInsert, TUpdate> 
        where T : class 
        where TSearch : BaseSearchObject 
        where TEntity : class, new() 
        where TInsert : class 
        where TUpdate : class
    {
        public BaseCrudService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public virtual async Task<T> CreateAsync(TInsert request)
        {
            var entity = new TEntity();
            MapInsertToEntity(entity, request);
            _context.Set<TEntity>().Add(entity);
            await BeforeInsert(entity, request);
            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeInsert(TEntity entity, TInsert request)
        {
            // Override in derived classes if needed
            await Task.CompletedTask;
        }

        protected virtual TEntity MapInsertToEntity(TEntity entity, TInsert request)
        {
            return _mapper.Map(request, entity);
        }

        public virtual async Task<T?> UpdateAsync(int id, TUpdate request)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return null;

            await BeforeUpdate(entity, request);
            MapUpdateToEntity(entity, request);
            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeUpdate(TEntity entity, TUpdate request)
        {
            // Override in derived classes if needed
            await Task.CompletedTask;
        }

        protected virtual void MapUpdateToEntity(TEntity entity, TUpdate request)
        {
            _mapper.Map(request, entity);
        }

        public virtual async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return false;

            await BeforeDelete(entity);
            _context.Set<TEntity>().Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

        protected virtual async Task BeforeDelete(TEntity entity)
        {
            // Override in derived classes if needed
            await Task.CompletedTask;
        }
    }
}
