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
        public DbSet<Message> Messages { get; set; }

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

            modelBuilder.Entity<Message>().HasOne(m => m.FromUser)
                .WithMany(u => u.SentMessages)
                .HasForeignKey(m => m.FromUserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Message>().HasOne(m => m.ToUser)
                .WithMany(u => u.ReceivedMessages)
                .HasForeignKey(m => m.ToUserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Message>().HasOne(m => m.StartedByAdmin)
                .WithMany(u => u.StartedChats)
                .HasForeignKey(m => m.StartedByAdminId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}
