using Microsoft.AspNetCore.Mvc;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DataSeedController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        public DataSeedController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("seed")]
        public IActionResult Seed()
        {
            // Payment Methods
            if (!_context.PaymentMethods.Any())
            {
                _context.PaymentMethods.AddRange(new[]
                {
                    new PaymentMethod { Name = "Credit Card", Description = "Credit card payment" },
                    new PaymentMethod { Name = "Debit Card", Description = "Debit card payment" },
                    new PaymentMethod { Name = "PayPal", Description = "PayPal payment" },
                    new PaymentMethod { Name = "Bank Transfer", Description = "Bank transfer payment" },
                    new PaymentMethod { Name = "Cash", Description = "Cash payment" }
                });
            }

            // Payment Statuses
            if (!_context.PaymentStatuses.Any())
            {
                _context.PaymentStatuses.AddRange(new[]
                {
                    new PaymentStatus { Name = "Pending", Description = "Payment is pending" },
                    new PaymentStatus { Name = "Completed", Description = "Payment is completed" },
                    new PaymentStatus { Name = "Failed", Description = "Payment has failed" },
                    new PaymentStatus { Name = "Refunded", Description = "Payment has been refunded" },
                    new PaymentStatus { Name = "Partially Refunded", Description = "Payment has been partially refunded" },
                    new PaymentStatus { Name = "Cancelled", Description = "Payment has been cancelled" }
                });
            }

            // Roles
            if (!_context.Roles.Any())
            {
                _context.Roles.AddRange(new[]
                {
                    new Role { Name = "Admin", Description = "Administrator role" },
                    new Role { Name = "User", Description = "Regular user role" }
                });
            }

            // Users
            if (!_context.Users.Any())
            {
                var now = DateTime.UtcNow;
                _context.Users.AddRange(new[]
                {
                    new User
                    {
                        FirstName = "Admin",
                        LastName = "User",
                        Username = "admin",
                        Email = "admin@mosposudit.com",
                        PhoneNumber = "123456789",
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                        RoleId = _context.Roles.FirstOrDefault(r => r.Name == "Admin")?.Id ?? 1,
                        IsActive = true,
                        CreatedAt = now,
                        UpdateDate = now,
                        PasswordUpdateDate = now,
                        DeactivationDate = null
                    },
                    new User
                    {
                        FirstName = "Regular",
                        LastName = "User",
                        Username = "user",
                        Email = "user@mosposudit.com",
                        PhoneNumber = "987654321",
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                        RoleId = _context.Roles.FirstOrDefault(r => r.Name == "User")?.Id ?? 2,
                        IsActive = true,
                        CreatedAt = now,
                        UpdateDate = now,
                        PasswordUpdateDate = now,
                        DeactivationDate = null
                    }
                });
            }

            _context.SaveChanges();
            return Ok("Seed podaci su uspješno dodani.");
        }
    }
}