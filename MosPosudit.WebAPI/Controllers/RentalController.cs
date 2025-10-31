using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.Requests.Rental;
using MosPosudit.Model.Responses.Rental;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class RentalController : ControllerBase
    {
        private readonly IRentalService _rentalService;

        public RentalController(IRentalService rentalService)
        {
            _rentalService = rentalService ?? throw new ArgumentNullException(nameof(rentalService));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<RentalResponse>>> Get([FromQuery] RentalSearchObject? search = null)
        {
            try
            {
                var result = await _rentalService.GetAsResponse(search);
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
        public async Task<ActionResult<RentalResponse>> GetById(int id)
        {
            try
            {
                var result = await _rentalService.GetByIdAsResponse(id);
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
        public async Task<ActionResult<RentalResponse>> Insert([FromBody] RentalInsertRequest insert)
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
                    // In production, this should require authentication
                    if (insert.UserId == 0)
                        return Unauthorized("User ID is required");
                    userId = insert.UserId;
                }
                else
                {
                    // Override UserId from authenticated context
                    insert.UserId = userId;
                }

                var result = await _rentalService.InsertAsResponse(insert);
                return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
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

        [HttpPost("{id}/payment-link")]
        public async Task<ActionResult<object>> GeneratePaymentLink(int id)
        {
            try
            {
                var baseUrl = $"{Request.Scheme}://{Request.Host}";
                var result = await _rentalService.GeneratePaymentLinkAsync(id, baseUrl);
                return Ok(result);
            }
            catch (Model.Exceptions.NotFoundException ex)
            {
                return NotFound(ex.Message);
            }
            catch (Model.Exceptions.ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<RentalResponse>> Update(int id, [FromBody] RentalUpdateRequest update)
        {
            try
            {
                if (update == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _rentalService.UpdateAsResponse(id, update);
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
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<RentalResponse>> Patch(int id, [FromBody] RentalPatchRequest patch)
        {
            try
            {
                if (patch == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _rentalService.PatchAsResponse(id, patch);
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
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<RentalResponse>> Delete(int id)
        {
            try
            {
                var result = await _rentalService.DeleteAsResponse(id);
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

        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<RentalResponse>>> GetByUserId(int userId)
        {
            try
            {
                // Verify user can only access their own rentals (unless admin)
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int authenticatedUserId))
                {
                    var role = User.FindFirst(ClaimTypes.Role)?.Value;
                    if (role != "Admin" && authenticatedUserId != userId)
                    {
                        return Forbid("You can only access your own rentals");
                    }
                }

                var result = await _rentalService.GetByUserId(userId);
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

        [HttpGet("availability/{toolId}")]
        public async Task<ActionResult<bool>> CheckAvailability(
            int toolId,
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate)
        {
            try
            {
                var isAvailable = await _rentalService.CheckAvailability(toolId, startDate, endDate);
                return Ok(new { toolId, startDate, endDate, isAvailable });
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

        [HttpGet("booked-dates/{toolId}")]
        public async Task<ActionResult<IEnumerable<DateTime>>> GetBookedDates(
            int toolId,
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            try
            {
                var bookedDates = await _rentalService.GetBookedDates(toolId, startDate, endDate);
                return Ok(bookedDates);
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

