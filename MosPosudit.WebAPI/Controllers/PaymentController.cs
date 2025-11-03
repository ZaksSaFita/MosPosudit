using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Requests.Payment;
using MosPosudit.Model.Responses;
using MosPosudit.Model.Responses.Payment;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentController : BaseCrudController<PaymentResponse, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest>
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService service) : base(service)
        {
            _paymentService = service;
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<PaymentResponse>> Get([FromQuery] PaymentSearchObject? search = null)
        {
            return await base.Get(search);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<PaymentResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        [Authorize]
        public override async Task<PaymentResponse> Create([FromBody] PaymentInsertRequest request)
        {
            return await base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<PaymentResponse?> Update(int id, [FromBody] PaymentUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpPost("paypal/create")]
        [Authorize]
        public async Task<ActionResult<PayPalOrderResponse>> CreatePayPalOrder([FromBody] PayPalCreateOrderRequest request)
        {
            try
            {
                var result = await _paymentService.CreatePayPalOrderAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("paypal/return")]
        [AllowAnonymous]
        public async Task<ActionResult> PayPalReturn([FromQuery] string? token)
        {
            try
            {
                if (string.IsNullOrEmpty(token))
                {
                    var orderId = Request.Query["order_id"].FirstOrDefault();
                    if (string.IsNullOrEmpty(orderId))
                    {
                        return BadRequest(new { message = "Missing PayPal order ID (token or order_id parameter)" });
                    }
                    token = orderId;
                }

                var result = await _paymentService.CompletePayPalPaymentAsync(token);
                
                return Ok(new { 
                    success = true, 
                    message = "Payment completed successfully",
                    orderId = result.DatabaseOrderId,
                    paymentId = result.DatabasePaymentId
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("paypal/cancel")]
        [AllowAnonymous]
        public ActionResult PayPalCancel()
        {
            return Ok(new { message = "Payment cancelled" });
        }
    }
}

