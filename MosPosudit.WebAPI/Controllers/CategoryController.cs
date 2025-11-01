using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Category;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.Category;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoryController : BaseCrudController<CategoryResponse, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest>
    {
        public CategoryController(ICategoryService service) : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<CategoryResponse>> Get([FromQuery] CategorySearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<CategoryResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override async Task<CategoryResponse> Create([FromBody] CategoryInsertRequest request)
        {
            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<CategoryResponse?> Update(int id, [FromBody] CategoryUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }
    }
}
