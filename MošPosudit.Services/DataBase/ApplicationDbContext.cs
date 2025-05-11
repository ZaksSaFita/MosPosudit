using Microsoft.EntityFrameworkCore;
using MošPosudit.Services.DataBase.Data;
using MošPosudit.Services.DataBase.Extensions;

namespace MošPosudit.Services.DataBase
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
        public DbSet<ToolCondition> ToolConditions { get; set; }
        public DbSet<Rental> Rentals { get; set; }
        public DbSet<RentalStatus> RentalStatuses { get; set; }
        public DbSet<RentalItem> RentalItems { get; set; }
        public DbSet<MaintenanceLog> MaintenanceLogs { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<PaymentTransaction> PaymentTransactions { get; set; }
        public DbSet<PaymentMethod> PaymentMethods { get; set; }
        public DbSet<PaymentStatus> PaymentStatuses { get; set; }
        public DbSet<Cart> Carts { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderStatus> OrderStatuses { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<UserFavorite> UserFavorites { get; set; }
        public DbSet<ToolDamageReport> ToolDamageReports { get; set; }
        public DbSet<RepairStatus> RepairStatuses { get; set; }
        public DbSet<ToolMaintenanceSchedule> ToolMaintenanceSchedules { get; set; }
        public DbSet<MaintenanceType> MaintenanceTypes { get; set; }
        public DbSet<ToolImage> ToolImages { get; set; }
        public DbSet<SystemLog> SystemLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Global configuration for decimal properties
            modelBuilder.ConfigureDecimalPrecision();

            // Configure ToolDamageReport relationships
            modelBuilder.Entity<ToolDamageReport>()
                .HasOne(t => t.ReportedBy)
                .WithMany()
                .HasForeignKey(t => t.ReportedById)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}