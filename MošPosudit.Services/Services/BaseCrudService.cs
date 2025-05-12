using Microsoft.EntityFrameworkCore;
using MošPosudit.Model.Exceptions;
using MošPosudit.Model.Messages;
using MošPosudit.Model.SearchObjects;
using MošPosudit.Services.DataBase;
using MošPosudit.Services.Interfaces;

namespace MošPosudit.Services.Services
{
    public class BaseCrudService<T, TSearch, TInsert, TUpdate, TPatch> : ICrudService<T, TSearch, TInsert, TUpdate, TPatch>
        where T : class
        where TSearch : BaseSearchObject
    {
        protected readonly ApplicationDbContext _context;
        protected readonly DbSet<T> _dbSet;

        public BaseCrudService(ApplicationDbContext context)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
            _dbSet = context.Set<T>();
        }

        public virtual async Task<IEnumerable<T>> Get(TSearch? search = null)
        {
            try
            {
                var query = _dbSet.AsQueryable();

                if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
                {
                    if (search.Page.Value < 1)
                        throw new ValidationException(ErrorMessages.InvalidRequest);
                    if (search.PageSize.Value < 1)
                        throw new ValidationException(ErrorMessages.InvalidRequest);

                    query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                                .Take(search.PageSize.Value);
                }

                return await query.ToListAsync();
            }
            catch (Exception ex) when (ex is not ValidationException && ex is not NotFoundException)
            {
                throw new Exception(ErrorMessages.ServerError, ex);
            }
        }

        public virtual async Task<T> GetById(int id)
        {
            try
            {
                if (id <= 0)
                    throw new ValidationException(ErrorMessages.InvalidRequest);

                var entity = await _dbSet.FindAsync(id);
                if (entity == null)
                    throw new NotFoundException(ErrorMessages.EntityNotFound);

                return entity;
            }
            catch (Exception ex) when (ex is not ValidationException && ex is not NotFoundException)
            {
                throw new Exception(ErrorMessages.ServerError, ex);
            }
        }

        public virtual async Task<T> Insert(TInsert insert)
        {
            try
            {
                if (insert == null)
                    throw new ValidationException(ErrorMessages.InvalidRequest);

                var entity = MapToEntity(insert);
                await _dbSet.AddAsync(entity);
                await _context.SaveChangesAsync();
                return entity;
            }
            catch (Exception ex) when (ex is not ValidationException)
            {
                throw new Exception(ErrorMessages.ServerError, ex);
            }
        }

        public virtual async Task<T> Update(int id, TUpdate update)
        {
            try
            {
                if (id <= 0)
                    throw new ValidationException(ErrorMessages.InvalidRequest);
                if (update == null)
                    throw new ValidationException(ErrorMessages.InvalidRequest);

                var entity = await GetById(id);
                MapToEntity(update, entity);
                await _context.SaveChangesAsync();
                return entity;
            }
            catch (Exception ex) when (ex is not ValidationException && ex is not NotFoundException)
            {
                throw new Exception(ErrorMessages.ServerError, ex);
            }
        }

        public virtual async Task<T> Delete(int id)
        {
            try
            {
                if (id <= 0)
                    throw new ValidationException(ErrorMessages.InvalidRequest);

                var entity = await GetById(id);
                _dbSet.Remove(entity);
                await _context.SaveChangesAsync();
                return entity;
            }
            catch (Exception ex) when (ex is not ValidationException && ex is not NotFoundException)
            {
                throw new Exception(ErrorMessages.ServerError, ex);
            }
        }

        public virtual async Task<T> Patch(int id, TPatch patch)
        {
            try
            {
                if (id <= 0)
                    throw new ValidationException(ErrorMessages.InvalidRequest);
                if (patch == null)
                    throw new ValidationException(ErrorMessages.InvalidRequest);

                var entity = await GetById(id);
                MapToEntity(patch, entity);
                await _context.SaveChangesAsync();
                return entity;
            }
            catch (Exception ex) when (ex is not ValidationException && ex is not NotFoundException)
            {
                throw new Exception(ErrorMessages.ServerError, ex);
            }
        }

        protected virtual T MapToEntity(TInsert insert)
        {
            throw new NotImplementedException(ErrorMessages.ServerError);
        }

        protected virtual void MapToEntity(TUpdate update, T entity)
        {
            throw new NotImplementedException(ErrorMessages.ServerError);
        }

        protected virtual void MapToEntity(TPatch patch, T entity)
        {
            throw new NotImplementedException(ErrorMessages.ServerError);
        }
    }
}