using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MosPosudit.Model.Exceptions;
using MosPosudit.Services.Interfaces;
using MosPosudit.Services.Services;

namespace MosPosudit.WebAPI.Controllers
{
    [Route("api/payment")]
    [ApiController]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IPayPalService _payPalService;
        private readonly IPaymentService _paymentService;
        private readonly ILogger<PaymentController> _logger;

        public PaymentController(
            IPayPalService payPalService,
            IPaymentService paymentService,
            ILogger<PaymentController> logger)
        {
            _payPalService = payPalService ?? throw new ArgumentNullException(nameof(payPalService));
            _paymentService = paymentService ?? throw new ArgumentNullException(nameof(paymentService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        [HttpGet("paypal/return")]
        [AllowAnonymous]
        public async Task<IActionResult> PayPalReturn([FromQuery] string? token, [FromQuery] string? PayerID, [FromQuery] string? rentalId)
        {
            try
            {
                // PayPal v2 API returns 'token' as the order ID in the return URL
                var orderId = token;
                
                if (string.IsNullOrEmpty(orderId))
                {
                    _logger.LogWarning("PayPal return callback missing token parameter");
                    return BadRequest("Missing payment token");
                }

                // Capture the payment using the order ID
                var success = await _payPalService.CapturePaymentAsync(orderId);

                if (success && !string.IsNullOrEmpty(rentalId) && int.TryParse(rentalId, out int rentalIdInt))
                {
                    // Update payment transaction in database
                    try
                    {
                        await _paymentService.ProcessPayPalReturnAsync(orderId, rentalIdInt);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to update payment transaction for rental {RentalId}", rentalIdInt);
                        // Don't fail the return - payment was successful
                    }
                }

                // Return JSON response for API clients, or redirect for web
                var acceptHeader = Request.Headers["Accept"].ToString();
                if (acceptHeader.Contains("application/json"))
                {
                    return Ok(new { success = true, message = "Payment completed successfully", rentalId = rentalId });
                }

                // For web browsers, redirect to success page
                return Redirect($"http://localhost:5001/payment/success?rentalId={rentalId ?? ""}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing PayPal return callback");
                
                var acceptHeader = Request.Headers["Accept"].ToString();
                if (acceptHeader.Contains("application/json"))
                {
                    return StatusCode(500, new { success = false, message = ex.Message });
                }

                return Redirect($"http://localhost:5001/payment/error?message={Uri.EscapeDataString(ex.Message)}");
            }
        }

        [HttpGet("paypal/cancel")]
        [AllowAnonymous]
        public IActionResult PayPalCancel([FromQuery] string? token, [FromQuery] string? rentalId)
        {
            _logger.LogInformation("PayPal payment cancelled for rental {RentalId}, token {Token}", rentalId, token);
            
            var acceptHeader = Request.Headers["Accept"].ToString();
            if (acceptHeader.Contains("application/json"))
            {
                return Ok(new { success = false, message = "Payment was cancelled", rentalId = rentalId });
            }

            // User cancelled the payment
            return Redirect($"http://localhost:5001/payment/cancelled?rentalId={rentalId ?? ""}");
        }
    }
}

