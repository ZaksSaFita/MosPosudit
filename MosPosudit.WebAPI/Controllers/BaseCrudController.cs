using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BaseCrudController<T, TSearch, TInsert, TUpdate> 
        : BaseController<T, TSearch> 
        where T : class 
        where TSearch : BaseSearchObject, new() 
        where TInsert : class 
        where TUpdate : class
    {
        protected readonly ICrudService<T, TSearch, TInsert, TUpdate> _crudService;

        public BaseCrudController(ICrudService<T, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _crudService = service;
        }

        [HttpPost]
        public virtual async Task<T> Create([FromBody] TInsert request)
        {
            return await _crudService.CreateAsync(request);
        }

        [HttpPut("{id}")]
        public virtual async Task<T?> Update(int id, [FromBody] TUpdate request)
        {
            return await _crudService.UpdateAsync(id, request);
        }

        [HttpDelete("{id}")]
        public virtual async Task<bool> Delete(int id)
        {
            return await _crudService.DeleteAsync(id);
        }
    }
} 
