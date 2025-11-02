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
        private readonly IToolService _toolService;

        public ToolController(IToolService service) : base(service)
        {
            _toolService = service;
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

        [HttpGet("{id}/availability")]
        [AllowAnonymous]
        public async Task<ActionResult<ToolAvailabilityResponse>> GetAvailability(
            int id,
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate)
        {
            if (startDate > endDate)
            {
                return BadRequest("Start date must be before or equal to end date");
            }

            if (startDate < DateTime.Today)
            {
                return BadRequest("Start date cannot be in the past");
            }

            // Minimum 1 day rental period
            var daysDifference = (endDate.Date - startDate.Date).Days;
            if (daysDifference < 1)
            {
                return BadRequest("Rental period must be at least 1 day");
            }

            var result = await _toolService.GetAvailabilityAsync(id, startDate, endDate);
            
            if (result == null)
            {
                return NotFound($"Tool with ID {id} not found");
            }

            return Ok(result);
        }
    }
}
