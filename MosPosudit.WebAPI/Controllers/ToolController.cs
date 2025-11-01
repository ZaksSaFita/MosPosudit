using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Tool;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.Tool;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ToolController : BaseCrudController<ToolResponse, ToolSearchObject, ToolInsertRequest, ToolUpdateRequest>
    {
        public ToolController(IToolService service) : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<ToolResponse>> Get([FromQuery] ToolSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<ToolResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override async Task<ToolResponse> Create([FromBody] ToolInsertRequest request)
        {
            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<ToolResponse?> Update(int id, [FromBody] ToolUpdateRequest request)
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
