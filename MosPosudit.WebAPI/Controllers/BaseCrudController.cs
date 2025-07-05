using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public abstract class BaseCrudController<T, TSearch, TInsert, TUpdate, TPatch> : ControllerBase
        where T : class
        where TSearch : BaseSearchObject
    {
        protected readonly ICrudService<T, TSearch, TInsert, TUpdate, TPatch> _service;

        protected BaseCrudController(ICrudService<T, TSearch, TInsert, TUpdate, TPatch> service)
        {
            _service = service ?? throw new ArgumentNullException(nameof(service));
        }

        [HttpGet]
        public virtual async Task<ActionResult<IEnumerable<T>>> Get([FromQuery] TSearch? search = null)
        {
            try
            {
                var result = await _service.Get(search);
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
        public virtual async Task<ActionResult<T>> GetById(int id)
        {
            try
            {
                var result = await _service.GetById(id);
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
        public virtual async Task<ActionResult<T>> Insert([FromBody] TInsert insert)
        {
            try
            {
                if (insert == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _service.Insert(insert);
                return CreatedAtAction(nameof(GetById), new { id = GetId(result) }, result);
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
        public virtual async Task<ActionResult<T>> Update(int id, [FromBody] TUpdate update)
        {
            try
            {
                if (update == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _service.Update(id, update);
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
        public virtual async Task<ActionResult<T>> Patch(int id, [FromBody] TPatch patch)
        {
            try
            {
                if (patch == null)
                    return BadRequest(ErrorMessages.InvalidRequest);

                var result = await _service.Patch(id, patch);
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
        [Authorize(Roles = "Admin")]
        public virtual async Task<ActionResult<T>> Delete(int id)
        {
            try
            {
                var result = await _service.Delete(id);
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

        protected abstract int GetId(T entity);
    }
} 
