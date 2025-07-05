using Microsoft.EntityFrameworkCore;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.DataBase.Extensions;
using BCrypt.Net;

namespace MosPosudit.Services.DataBase
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<Tool> Tools { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Rental> Rentals { get; set; }
        public DbSet<RentalItem> RentalItems { get; set; }
        public DbSet<MaintenanceLog> MaintenanceLogs { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<PaymentTransaction> PaymentTransactions { get; set; }
        public DbSet<PaymentMethod> PaymentMethods { get; set; }
        public DbSet<PaymentStatus> PaymentStatuses { get; set; }
        public DbSet<Cart> Carts { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<UserFavorite> UserFavorites { get; set; }
        public DbSet<ToolDamageReport> ToolDamageReports { get; set; }
        public DbSet<ToolMaintenanceSchedule> ToolMaintenanceSchedules { get; set; }
        public DbSet<ToolImage> ToolImages { get; set; }
        public DbSet<SystemLog> SystemLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Global configuration for decimal properties
            modelBuilder.ConfigureDecimalPrecision();


            // Configure relationships with OnDelete behavior
            modelBuilder.Entity<CartItem>().HasOne(ci => ci.Cart)
                .WithMany(c => c.Items)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<CartItem>().HasOne(ci => ci.Tool)
                .WithMany(t => t.CartItems)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<OrderItem>().HasOne(oi => oi.Order)
                .WithMany(o => o.OrderItems)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<OrderItem>().HasOne(oi => oi.Tool)
                .WithMany(t => t.OrderItems)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<RentalItem>().HasOne(ri => ri.Rental)
                .WithMany(r => r.RentalItems)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<RentalItem>().HasOne(ri => ri.Tool)
                .WithMany(t => t.RentalItems)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ToolImage>().HasOne(ti => ti.Tool)
                .WithMany(t => t.Images)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ToolDamageReport>().HasOne(td => td.ReportedBy)
                .WithMany(u => u.ReportedDamages)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ToolDamageReport>().HasOne(td => td.Tool)
                .WithMany(t => t.DamageReports)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ToolMaintenanceSchedule>().HasOne(tms => tms.Tool)
                .WithMany(t => t.MaintenanceSchedules)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ToolMaintenanceSchedule>().HasOne(tms => tms.AssignedTo)
                .WithMany(u => u.AssignedMaintenance)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Review>().HasOne(r => r.User)
                .WithMany(u => u.Reviews)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Review>().HasOne(r => r.Tool)
                .WithMany(t => t.Reviews)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserFavorite>().HasOne(uf => uf.User)
                .WithMany(u => u.Favorites)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserFavorite>().HasOne(uf => uf.Tool)
                .WithMany(t => t.Favorites)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Notification>().HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<PaymentTransaction>().HasOne(pt => pt.Rental)
                .WithMany(r => r.Payments)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<PaymentTransaction>().HasOne(pt => pt.Order)
                .WithMany(o => o.Payments)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<PaymentTransaction>().HasOne(pt => pt.User)
                .WithMany(u => u.PaymentTransactions)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<PaymentTransaction>().HasOne(pt => pt.PaymentMethod)
                .WithMany()
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<PaymentTransaction>().HasOne(pt => pt.Status)
                .WithMany()
                .OnDelete(DeleteBehavior.NoAction);

            // Seed payment methods
            modelBuilder.Entity<PaymentMethod>().HasData(
                new PaymentMethod { Id = 1, Name = "Credit Card", Description = "Credit card payment" },
                new PaymentMethod { Id = 2, Name = "Debit Card", Description = "Debit card payment" },
                new PaymentMethod { Id = 3, Name = "PayPal", Description = "PayPal payment" },
                new PaymentMethod { Id = 4, Name = "Bank Transfer", Description = "Bank transfer payment" },
                new PaymentMethod { Id = 5, Name = "Cash", Description = "Cash payment" }
            );

            // Seed payment statuses
            modelBuilder.Entity<PaymentStatus>().HasData(
                new PaymentStatus { Id = 1, Name = "Pending", Description = "Payment is pending" },
                new PaymentStatus { Id = 2, Name = "Completed", Description = "Payment is completed" },
                new PaymentStatus { Id = 3, Name = "Failed", Description = "Payment has failed" },
                new PaymentStatus { Id = 4, Name = "Refunded", Description = "Payment has been refunded" },
                new PaymentStatus { Id = 5, Name = "Partially Refunded", Description = "Payment has been partially refunded" },
                new PaymentStatus { Id = 6, Name = "Cancelled", Description = "Payment has been cancelled" }
            );


            // Seed roles
            modelBuilder.Entity<Role>().HasData(
                new Role { Id = 1, Name = "Admin", Description = "Administrator role" },
                new Role { Id = 2, Name = "User", Description = "Regular user role" }
            );

            // Seed users
            var now = DateTime.UtcNow;
            modelBuilder.Entity<User>().HasData(
                new User 
                { 
                    Id = 1,
                    FirstName = "Admin",
                    LastName = "User",
                    Username = "admin",
                    Email = "admin@mosposudit.com",
                    PhoneNumber = "123456789",
                    Address = "Admin Address",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                    RoleId = 1, // Admin role
                    IsActive = true,
                    CreatedAt = now,
                    UpdateDate = now,
                    PasswordUpdateDate = now,
                    DeactivationDate = null
                },
                new User 
                { 
                    Id = 2,
                    FirstName = "Regular",
                    LastName = "User",
                    Username = "user",
                    Email = "user@mosposudit.com",
                    PhoneNumber = "987654321",
                    Address = "User Address",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                    RoleId = 2, // User role
                    IsActive = true,
                    CreatedAt = now,
                    UpdateDate = now,
                    PasswordUpdateDate = now,
                    DeactivationDate = null
                }
            );
        }
    }
}
