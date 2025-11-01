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
        public DbSet<Review> Reviews { get; set; }
        public DbSet<UserFavorite> UserFavorites { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Message> Messages { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Payment> Payments { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Global configuration for decimal properties
            modelBuilder.ConfigureDecimalPrecision();


            // Configure relationships with OnDelete behavior

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

            modelBuilder.Entity<Order>().HasOne(o => o.User)
                .WithMany(u => u.Orders)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<OrderItem>().HasOne(oi => oi.Order)
                .WithMany(o => o.OrderItems)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<OrderItem>().HasOne(oi => oi.Tool)
                .WithMany(t => t.OrderItems)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Payment>().HasOne(p => p.Order)
                .WithMany(o => o.Payments)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
