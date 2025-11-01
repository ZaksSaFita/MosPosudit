using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Review;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.Review;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReviewController : BaseCrudController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        private readonly IReviewService _reviewService;

        public ReviewController(IReviewService service) : base(service)
        {
            _reviewService = service;
        }

        [HttpGet]
        [AllowAnonymous]
        public override async Task<PagedResult<ReviewResponse>> Get([FromQuery] ReviewSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override async Task<ReviewResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        public override async Task<ReviewResponse> Create([FromBody] ReviewInsertRequest request)
        {
            // Get user ID from authenticated user context
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                // For testing without auth, allow userId in request body
                if (request.UserId == 0)
                    throw new UnauthorizedAccessException("User ID is required");
                userId = request.UserId;
            }
            else
            {
                request.UserId = userId;
            }

            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize]
        public override async Task<ReviewResponse?> Update(int id, [FromBody] ReviewUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpGet("tool/{toolId}")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<ReviewResponse>>> GetByToolId(int toolId)
        {
            var result = await _reviewService.GetByToolIdAsResponse(toolId);
            return Ok(result);
        }
    }
}
