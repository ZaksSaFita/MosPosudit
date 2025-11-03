using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.Order;
using MosPosudit.Model.Requests.Payment;
using MosPosudit.Model.Responses.Payment;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using PayPalCheckoutSdk.Core;
using PayPalCheckoutSdk.Orders;
using PayPalHttp;
using MapsterMapper;
using System.Linq;
using System.Text.Json;
using DataOrder = MosPosudit.Services.DataBase.Data.Order;

namespace MosPosudit.Services.Services
{
    public class PaymentService : BaseCrudService<PaymentResponse, PaymentSearchObject, Payment, PaymentInsertRequest, PaymentUpdateRequest>, IPaymentService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<PaymentService> _logger;
        private readonly IToolService _toolService;
        private readonly IMessageService _messageService;
        private PayPalEnvironment? _paypalEnvironment;

        public PaymentService(
            ApplicationDbContext context, 
            IMapper mapper,
            IConfiguration configuration,
            ILogger<PaymentService> logger,
            IToolService toolService,
            IMessageService messageService) : base(context, mapper)
        {
            _configuration = configuration;
            _logger = logger;
            _toolService = toolService;
            _messageService = messageService;
        }

        protected override IQueryable<Payment> ApplyFilter(IQueryable<Payment> query, PaymentSearchObject search)
        {
            query = query.Include(p => p.Order);

            if (search.OrderId.HasValue)
                query = query.Where(x => x.OrderId == search.OrderId.Value);

            if (search.IsCompleted.HasValue)
                query = query.Where(x => x.IsCompleted == search.IsCompleted.Value);

            if (search.PaymentDateFrom.HasValue)
                query = query.Where(x => x.PaymentDate >= search.PaymentDateFrom.Value);

            if (search.PaymentDateTo.HasValue)
                query = query.Where(x => x.PaymentDate <= search.PaymentDateTo.Value);

            return query;
        }

        public override async Task<PaymentResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<Payment>()
                .Include(p => p.Order)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected override async Task BeforeInsert(Payment entity, PaymentInsertRequest request)
        {
            entity.CreatedAt = DateTime.UtcNow;
            if (request.PaymentDate.HasValue)
                entity.PaymentDate = request.PaymentDate.Value;
            else
                entity.PaymentDate = DateTime.UtcNow;

            // If payment is completed, mark order confirmation email as sent
            if (entity.IsCompleted)
            {
                var order = await _context.Set<DataOrder>().FindAsync(entity.OrderId);
                if (order != null)
                {
                    order.ConfirmationEmailSent = true;
                }
            }
        }

        protected override async Task BeforeUpdate(Payment entity, PaymentUpdateRequest request)
        {
            // If marking payment as completed, mark order confirmation email as sent
            if (request.IsCompleted.HasValue && request.IsCompleted.Value && !entity.IsCompleted)
            {
                var order = await _context.Set<DataOrder>().FindAsync(entity.OrderId);
                if (order != null)
                {
                    order.ConfirmationEmailSent = true;
                }
            }
        }

        // ==================== PayPal Methods ====================

        // Creates PayPal order and returns approval URL for user to complete payment
        public async Task<PayPalOrderResponse> CreatePayPalOrderAsync(PayPalCreateOrderRequest request)
        {
            try
            {
                var orderData = request.OrderData;
                
                // Basic validation
                if (orderData.OrderItems == null || orderData.OrderItems.Count == 0)
                    throw new ValidationException("Order must contain at least one item");

                // Get PayPal client
                var paypalClient = GetPayPalClient();
                if (paypalClient == null)
                    throw new ValidationException("PayPal is not configured. Please set PayPal:ClientId and PayPal:Secret in configuration.");

                var returnUrl = _configuration["PayPal:ReturnUrl"];
                var cancelUrl = _configuration["PayPal:CancelUrl"];
                if (string.IsNullOrEmpty(returnUrl) || string.IsNullOrEmpty(cancelUrl))
                    throw new ValidationException("PayPal ReturnUrl and CancelUrl must be configured.");

                // Store order data in PayPal CustomId for later retrieval
                var orderDataJson = System.Text.Json.JsonSerializer.Serialize(orderData);
                
                // Build PayPal order request
                int days = (orderData.EndDate - orderData.StartDate).Days + 1;
                decimal totalAmount = 0;
                var items = new List<Item>();

                foreach (var itemRequest in orderData.OrderItems)
                {
                    var tool = await _context.Set<Tool>().FindAsync(itemRequest.ToolId);
                    if (tool == null)
                        throw new ValidationException($"Tool with ID {itemRequest.ToolId} not found");

                    var itemTotalPrice = tool.DailyRate * itemRequest.Quantity * days;
                    totalAmount += itemTotalPrice;

                    items.Add(new Item
                    {
                        Name = tool.Name ?? "Tool",
                        Description = $"{tool.Description ?? ""} (Qty: {itemRequest.Quantity}, {days} day(s))".Trim(),
                        UnitAmount = new Money
                        {
                            CurrencyCode = "USD",
                            Value = itemTotalPrice.ToString("F2", System.Globalization.CultureInfo.InvariantCulture)
                        },
                        Quantity = "1",
                        Sku = tool.Id.ToString()
                    });
                }

                if (items.Count == 0)
                    throw new ValidationException("Order must contain at least one valid item");

                var totalValue = totalAmount.ToString("F2", System.Globalization.CultureInfo.InvariantCulture);

                var paypalOrderRequest = new PayPalCheckoutSdk.Orders.OrderRequest
                {
                    CheckoutPaymentIntent = "CAPTURE",
                    ApplicationContext = new ApplicationContext
                    {
                        ReturnUrl = returnUrl,
                        CancelUrl = cancelUrl,
                        BrandName = "MosPosudit",
                        LandingPage = "NO_PREFERENCE",
                        UserAction = "PAY_NOW"
                    },
                    PurchaseUnits = new List<PurchaseUnitRequest>
                    {
                        new PurchaseUnitRequest
                        {
                            Description = "Tool Rental Order",
                            CustomId = orderDataJson, // Store order data here
                            AmountWithBreakdown = new AmountWithBreakdown
                            {
                                CurrencyCode = "USD",
                                Value = totalValue,
                                AmountBreakdown = new AmountBreakdown
                                {
                                    ItemTotal = new Money
                                    {
                                        CurrencyCode = "USD",
                                        Value = totalValue
                                    }
                                }
                            },
                            Items = items
                        }
                    }
                };

                var orderRequest = new OrdersCreateRequest();
                orderRequest.Prefer("return=representation");
                orderRequest.RequestBody(paypalOrderRequest);

                var response = await paypalClient.Execute(orderRequest);
                var result = response.Result<PayPalCheckoutSdk.Orders.Order>();

                var approvalUrl = result.Links.FirstOrDefault(l => l.Rel == "approve")?.Href ?? string.Empty;
                if (string.IsNullOrEmpty(approvalUrl))
                    throw new ValidationException("Failed to get PayPal approval URL");

                return new PayPalOrderResponse
                {
                    OrderId = result.Id,
                    ApprovalUrl = approvalUrl,
                    Status = result.Status
                };
            }
            catch (HttpException ex)
            {
                _logger.LogError(ex, "PayPal API error: {Message}", ex.Message);
                var errorMessage = ex.Message;
                if (errorMessage.Contains("401") || errorMessage.Contains("Unauthorized") || errorMessage.Contains("authentication"))
                {
                    errorMessage = "PayPal authentication failed. Please check your PayPal ClientId and Secret in configuration.";
                }
                throw new ValidationException($"PayPal error: {errorMessage}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating PayPal order: {Message}", ex.Message);
                throw;
            }
        }

        // Verifies PayPal payment status by checking PayPal API
        private async Task<(bool IsSuccess, decimal Amount, string TransactionId, OrderInsertRequest OrderData)> VerifyPayPalPaymentAsync(string paypalOrderId)
        {
            var paypalClient = GetPayPalClient();
            if (paypalClient == null)
                throw new ValidationException("PayPal is not configured.");

            // Capture the order
            var captureRequest = new OrdersCaptureRequest(paypalOrderId);
            captureRequest.Prefer("return=representation");
            
            // PayPal capture requires an empty OrderActionRequest body (empty JSON {})
            // This is required by PayPal API - without it, we get UNSUPPORTED_MEDIA_TYPE
            var emptyAction = new OrderActionRequest();
            captureRequest.RequestBody(emptyAction);
            
            var response = await paypalClient.Execute(captureRequest);
            var result = response.Result<PayPalCheckoutSdk.Orders.Order>();

            if (result.Status != "COMPLETED")
                throw new ValidationException($"PayPal order status is {result.Status}, expected COMPLETED");

            // Get payment details
            var purchaseUnit = result.PurchaseUnits?.FirstOrDefault();
            if (purchaseUnit == null || purchaseUnit.Payments == null || purchaseUnit.Payments.Captures == null)
                throw new ValidationException("Invalid PayPal order response");

            var capture = purchaseUnit.Payments.Captures.FirstOrDefault();
            if (capture == null)
                throw new ValidationException("No capture found in PayPal order");

            var amount = decimal.Parse(capture.Amount?.Value ?? "0");
            var transactionId = capture.Id ?? string.Empty;

            // Get order data from PayPal CustomId
            OrderInsertRequest orderData;
            if (purchaseUnit.CustomId != null)
            {
                orderData = System.Text.Json.JsonSerializer.Deserialize<OrderInsertRequest>(purchaseUnit.CustomId)
                    ?? throw new ValidationException("Could not deserialize order data from PayPal");
            }
            else
            {
                throw new ValidationException("Could not find order data in PayPal order");
            }

            return (true, amount, transactionId, orderData);
        }

        // Saves Order and Payment to database after successful PayPal verification
        private async Task<(int OrderId, int PaymentId)> SavePaymentToDatabaseAsync(OrderInsertRequest orderData, decimal amount, string transactionId)
        {
            // Validate tools exist and check availability for selected date range
            foreach (var item in orderData.OrderItems)
            {
                var tool = await _context.Set<Tool>().FindAsync(item.ToolId);
                if (tool == null)
                    throw new ValidationException($"Tool with ID {item.ToolId} no longer exists");

                // Check availability for this tool for the selected date range
                var availability = await _toolService.GetAvailabilityAsync(
                    item.ToolId,
                    orderData.StartDate,
                    orderData.EndDate
                );

                if (availability == null)
                    throw new ValidationException($"Unable to check availability for tool ID {item.ToolId}");

                // Check each day in the selected date range
                var currentDate = orderData.StartDate.Date;
                var endDate = orderData.EndDate.Date;

                while (currentDate <= endDate)
                {
                    var dateKey = currentDate.ToString("yyyy-MM-dd");
                    var available = availability.DailyAvailability.ContainsKey(dateKey)
                        ? availability.DailyAvailability[dateKey]
                        : 0;

                    if (available < item.Quantity)
                    {
                        throw new ValidationException(
                            $"Not enough {tool.Name} available. " +
                            $"Requested: {item.Quantity}, Available on {currentDate:dd.MM.yyyy}: {available}/{availability.TotalQuantity}"
                        );
                    }

                    currentDate = currentDate.AddDays(1);
                }
            }

            // Create Order in database
            var order = new DataOrder
            {
                UserId = orderData.UserId,
                StartDate = orderData.StartDate,
                EndDate = orderData.EndDate,
                TermsAccepted = orderData.TermsAccepted,
                ConfirmationEmailSent = false,
                IsReturned = false,
                CreatedAt = DateTime.UtcNow
            };

            // Calculate total and create order items, decrease tool quantity
            decimal totalAmount = 0;
            int days = (orderData.EndDate - orderData.StartDate).Days + 1;

            foreach (var itemRequest in orderData.OrderItems)
            {
                var tool = await _context.Set<Tool>().FindAsync(itemRequest.ToolId);
                if (tool == null) 
                    throw new ValidationException($"Tool with ID {itemRequest.ToolId} not found");

                var dailyRate = tool.DailyRate;
                var itemTotalPrice = dailyRate * itemRequest.Quantity * days;

                order.OrderItems.Add(new OrderItem
                {
                    ToolId = itemRequest.ToolId,
                    Quantity = itemRequest.Quantity,
                    DailyRate = dailyRate,
                    TotalPrice = itemTotalPrice
                });

                totalAmount += itemTotalPrice;

                // Don't decrease tool quantity - availability is calculated based on orders, not fixed quantity
                // Quantity represents original stock and doesn't change when orders are created
                // Availability is calculated dynamically using GetAvailabilityAsync method
            }

            order.TotalAmount = totalAmount;
            _context.Set<DataOrder>().Add(order);
            await _context.SaveChangesAsync(); // Save to get Order.Id

            // Load order with items for email
            var orderWithItems = await _context.Set<DataOrder>()
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.Id == order.Id);
            
            if (orderWithItems == null)
                throw new ValidationException("Failed to load order after creation");

            // Create Payment entity
            var payment = new Payment
            {
                OrderId = order.Id,
                Amount = amount,
                IsCompleted = true,
                TransactionId = transactionId,
                PaymentDate = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };

            _context.Set<Payment>().Add(payment);
            await _context.SaveChangesAsync();

            // Get user email and send confirmation email
            var user = await _context.Set<User>().FindAsync(orderData.UserId);
            if (user != null && !string.IsNullOrEmpty(user.Email))
            {
                // Build email content
                var emailSubject = $"Order Confirmation - Order #{orderWithItems.Id}";
                var emailBody = BuildOrderConfirmationEmail(orderWithItems, user, orderData);
                
                // Send email via RabbitMQ
                try
                {
                    _logger.LogInformation($"Attempting to send order confirmation email to {user.Email} for order {orderWithItems.Id}");
                    _messageService.PublishEmail(user.Email, emailSubject, emailBody, isHtml: true);
                    _logger.LogInformation($"Order confirmation email queued successfully for user {user.Email} for order {orderWithItems.Id}");
                    
                    orderWithItems.ConfirmationEmailSent = true;
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"Order {orderWithItems.Id} marked as ConfirmationEmailSent=true");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Failed to queue order confirmation email for order {orderWithItems.Id}. Error: {ex.Message}");
                    // Don't fail the payment if email fails - just log it
                    // Email will be queued later or sent manually
                }
            }
            else
            {
                _logger.LogWarning($"User {orderData.UserId} has no email address. Cannot send order confirmation email.");
            }

            return (orderWithItems.Id, payment.Id);
        }

        // Completes PayPal payment by verifying payment status and saving to database
        public async Task<PayPalCaptureResponse> CompletePayPalPaymentAsync(string paypalOrderId)
        {
            try
            {
                // STEP 1: Verify PayPal payment - only checks PayPal API
                var (isSuccess, amount, transactionId, orderData) = await VerifyPayPalPaymentAsync(paypalOrderId);
                
                if (!isSuccess)
                    throw new ValidationException("PayPal payment verification failed");

                // STEP 2: Save to database - only called if PayPal verification succeeded
                var (orderId, paymentId) = await SavePaymentToDatabaseAsync(orderData, amount, transactionId);

                return new PayPalCaptureResponse
                {
                    OrderId = paypalOrderId,
                    TransactionId = transactionId,
                    Status = "COMPLETED",
                    Amount = amount,
                    IsCompleted = true,
                    DatabaseOrderId = orderId,
                    DatabasePaymentId = paymentId
                };
            }
            catch (HttpException ex)
            {
                _logger.LogError(ex, "PayPal API error: {Message}", ex.Message);
                var errorMessage = ex.Message;
                if (errorMessage.Contains("401") || errorMessage.Contains("Unauthorized") || errorMessage.Contains("authentication"))
                {
                    errorMessage = "PayPal authentication failed. Please check your PayPal credentials.";
                }
                throw new ValidationException($"PayPal error: {errorMessage}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error completing PayPal payment: {Message}", ex.Message);
                throw;
            }
        }

        // ==================== Private Helper Methods ====================

        private string BuildOrderConfirmationEmail(DataOrder order, User user, OrderInsertRequest orderData)
        {
            var days = (orderData.EndDate - orderData.StartDate).Days + 1;
            var orderItemsHtml = new System.Text.StringBuilder();
            
            foreach (var item in order.OrderItems)
            {
                var tool = _context.Set<Tool>().Find(item.ToolId);
                var toolName = tool?.Name ?? "Unknown Tool";
                orderItemsHtml.AppendLine($@"
                    <tr>
                        <td style=""padding: 10px; border-bottom: 1px solid #ddd;"">{toolName}</td>
                        <td style=""padding: 10px; border-bottom: 1px solid #ddd; text-align: center;"">{item.Quantity}</td>
                        <td style=""padding: 10px; border-bottom: 1px solid #ddd; text-align: right;"">€{item.DailyRate:F2}</td>
                        <td style=""padding: 10px; border-bottom: 1px solid #ddd; text-align: right;"">€{item.TotalPrice:F2}</td>
                    </tr>");
            }

            return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset=""utf-8"">
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
        .content {{ background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }}
        .info-box {{ background-color: white; padding: 15px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #4CAF50; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th {{ background-color: #4CAF50; color: white; padding: 12px; text-align: left; }}
        .total {{ font-size: 18px; font-weight: bold; color: #4CAF50; text-align: right; margin-top: 20px; }}
        .footer {{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; }}
    </style>
</head>
<body>
    <div class=""container"">
        <div class=""header"">
            <h1>Order Confirmation</h1>
            <p>Thank you for your order!</p>
        </div>
        <div class=""content"">
            <p>Dear {user.FirstName} {user.LastName},</p>
            <p>Your order has been confirmed. We have received your payment successfully.</p>
            
            <div class=""info-box"">
                <strong>Order Details:</strong><br>
                Order Number: <strong>#{order.Id}</strong><br>
                Order Date: <strong>{order.CreatedAt:dd.MM.yyyy HH:mm}</strong><br>
                Rental Period: <strong>{orderData.StartDate:dd.MM.yyyy}</strong> to <strong>{orderData.EndDate:dd.MM.yyyy}</strong><br>
                Duration: <strong>{days} day{(days > 1 ? "s" : "")}</strong>
            </div>

            <h3>Order Items:</h3>
            <table>
                <thead>
                    <tr>
                        <th>Tool</th>
                        <th style=""text-align: center;"">Quantity</th>
                        <th style=""text-align: right;"">Daily Rate</th>
                        <th style=""text-align: right;"">Total</th>
                    </tr>
                </thead>
                <tbody>
                    {orderItemsHtml}
                </tbody>
            </table>
            
            <div class=""total"">
                Total Amount: €{order.TotalAmount:F2}
            </div>

            <p>Your rental period starts on <strong>{orderData.StartDate:dd.MM.yyyy}</strong> and ends on <strong>{orderData.EndDate:dd.MM.yyyy}</strong>.</p>
            
            <p>If you have any questions about your order, please contact us.</p>
            
            <div class=""footer"">
                <p>Best regards,<br>MošPosudit Team</p>
                <p>This is an automated email. Please do not reply to this message.</p>
            </div>
        </div>
    </div>
</body>
</html>";
        }

        private PayPalEnvironment GetPayPalEnvironment()
        {
            if (_paypalEnvironment != null)
                return _paypalEnvironment;

            var clientId = _configuration["PayPal:ClientId"];
            var secret = _configuration["PayPal:Secret"];
            var mode = _configuration["PayPal:Mode"] ?? "sandbox";

            if (string.IsNullOrEmpty(clientId) || string.IsNullOrEmpty(secret))
                throw new ValidationException("PayPal credentials are not configured. Please set PayPal:ClientId and PayPal:Secret in configuration.");

            _paypalEnvironment = mode.ToLower() == "live"
                ? new LiveEnvironment(clientId, secret)
                : new SandboxEnvironment(clientId, secret);

            return _paypalEnvironment;
        }

        private PayPalHttpClient? GetPayPalClient()
        {
            try
            {
                var environment = GetPayPalEnvironment();
                return new PayPalHttpClient(environment);
            }
            catch (ValidationException)
            {
                return null; // PayPal not configured
            }
        }

    }
}

