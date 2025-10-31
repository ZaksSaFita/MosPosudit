using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.Requests.Category;
using MosPosudit.Model.Responses.Category;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoryController : ControllerBase
    {
        protected readonly ICategoryService _service;

        public CategoryController(ICategoryService categoryService)
        {
            _service = categoryService ?? throw new ArgumentNullException(nameof(categoryService));
        }

        [HttpGet]
        public virtual async Task<ActionResult<IEnumerable<CategoryResponse>>> Get([FromQuery] CategorySearchObject? search = null)
        {
            try
            {
                var result = await _service.GetAsResponse(search);
                return Ok(result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpGet("{id}")]
        public virtual async Task<ActionResult<CategoryResponse>> GetById(int id)
        {
            try
            {
                var result = await _service.GetByIdAsResponse(id);
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
            catch (Exception ex)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPost]
        public virtual async Task<ActionResult<CategoryResponse>> Insert([FromBody] CategoryInsertRequest insert)
        {
            try
            {
                if (insert == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _service.InsertAsResponse(insert);
                return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
            }
            catch (ValidationException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPut("{id}")]
        public virtual async Task<ActionResult<CategoryResponse>> Update(int id, [FromBody] CategoryUpdateRequest update)
        {
            try
            {
                if (update == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _service.UpdateAsResponse(id, update);
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
            catch (Exception ex)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpPatch("{id}")]
        public virtual async Task<ActionResult<CategoryResponse>> Patch(int id, [FromBody] CategoryPatchRequest patch)
        {
            try
            {
                if (patch == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _service.PatchAsResponse(id, patch);
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
            catch (Exception ex)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }

        [HttpDelete("{id}")]
        public virtual async Task<ActionResult<CategoryResponse>> Delete(int id)
        {
            try
            {
                var result = await _service.DeleteAsResponse(id);
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
            catch (Exception ex)
            {
                return StatusCode(500, ErrorMessages.ServerError);
            }
        }
    }
}

