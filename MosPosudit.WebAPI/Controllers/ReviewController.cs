using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.Requests.Review;
using MosPosudit.Model.Responses.Review;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ReviewController : ControllerBase
    {
        private readonly IReviewService _reviewService;

        public ReviewController(IReviewService reviewService)
        {
            _reviewService = reviewService ?? throw new ArgumentNullException(nameof(reviewService));
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<ReviewResponse>>> Get([FromQuery] ReviewSearchObject? search = null)
        {
            try
            {
                var result = await _reviewService.GetAsResponse(search);
                return Ok(result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<ReviewResponse>> GetById(int id)
        {
            try
            {
                var result = await _reviewService.GetByIdAsResponse(id);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPost]
        public async Task<ActionResult<ReviewResponse>> Insert([FromBody] ReviewInsertRequest insert)
        {
            try
            {
                if (insert == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                // Get user ID from authenticated user context
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    // For testing without auth, allow userId in request body
                    if (insert.UserId == 0)
                        return Unauthorized("User ID is required");
                    userId = insert.UserId;
                }
                else
                {
                    insert.UserId = userId;
                }

                var result = await _reviewService.InsertAsResponse(insert);
                return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPut("{id}")]
        [Authorize]
        public async Task<ActionResult<ReviewResponse>> Update(int id, [FromBody] ReviewUpdateRequest update)
        {
            try
            {
                if (update == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _reviewService.UpdateAsResponse(id, update);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPatch("{id}")]
        [Authorize]
        public async Task<ActionResult<ReviewResponse>> Patch(int id, [FromBody] ReviewPatchRequest patch)
        {
            try
            {
                if (patch == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _reviewService.PatchAsResponse(id, patch);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpDelete("{id}")]
        [Authorize]
        public async Task<ActionResult<ReviewResponse>> Delete(int id)
        {
            try
            {
                var result = await _reviewService.DeleteAsResponse(id);
                return Ok(result);
            }
            catch (NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpGet("tool/{toolId}")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<ReviewResponse>>> GetByToolId(int toolId)
        {
            try
            {
                var result = await _reviewService.GetByToolIdAsResponse(toolId);
                return Ok(result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }
    }
}

