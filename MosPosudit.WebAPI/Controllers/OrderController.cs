using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Order;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.Order;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrderController : BaseCrudController<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        private readonly IOrderService _orderService;

        public OrderController(IOrderService service) : base(service)
        {
            _orderService = service;
        }

        [HttpGet]
        [Authorize]
        public override async Task<PagedResult<OrderResponse>> Get([FromQuery] OrderSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<OrderResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        [Authorize]
        public override async Task<OrderResponse> Create([FromBody] OrderInsertRequest request)
        {
            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<OrderResponse?> Update(int id, [FromBody] OrderUpdateRequest request)
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

