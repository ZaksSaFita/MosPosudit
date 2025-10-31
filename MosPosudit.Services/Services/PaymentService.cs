using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<PaymentService> _logger;

        public PaymentService(ApplicationDbContext context, ILogger<PaymentService> logger)
        {
            _context = context ?? throw new ArgumentNullException(nameof(context));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public async Task<bool> ProcessPayPalReturnAsync(string orderId, int rentalId)
        {
            try
            {
                var rental = await _context.Rentals
                    .Include(r => r.Payments)
                    .FirstOrDefaultAsync(r => r.Id == rentalId);

                if (rental == null)
                {
                    _logger.LogWarning("Rental {RentalId} not found for payment processing", rentalId);
                    return false;
                }

                // Find or create payment transaction
                var paymentTransaction = rental.Payments?.FirstOrDefault()
                    ?? new PaymentTransaction
                    {
                        RentalId = rental.Id,
                        UserId = rental.UserId,
                        PaymentMethod = "PayPal",
                        Status = "Pending",
                        Amount = rental.TotalAmount,
                        TransactionDate = DateTime.UtcNow,
                        TransactionId = orderId,
                        CreatedAt = DateTime.UtcNow,
                        ProcessedAt = DateTime.UtcNow
                    };

                paymentTransaction.TransactionId = orderId;
                paymentTransaction.ProcessedAt = DateTime.UtcNow;
                paymentTransaction.Status = "Completed";

                if (paymentTransaction.Id == 0)
                {
                    _context.PaymentTransactions.Add(paymentTransaction);
                }
                else
                {
                    _context.PaymentTransactions.Update(paymentTransaction);
                }

                await _context.SaveChangesAsync();
                _logger.LogInformation("Payment transaction updated for rental {RentalId}, order {OrderId}", rentalId, orderId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process PayPal return for rental {RentalId}, order {OrderId}", rentalId, orderId);
                return false;
            }
        }
    }
}

