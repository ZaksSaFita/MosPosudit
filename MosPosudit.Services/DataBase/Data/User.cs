using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [StringLength(50)]
        public string? FirstName { get; set; } = null;

        [StringLength(50)]
        public string? LastName { get; set; } = null;

        [EmailAddress]
        [StringLength(100)]
        public string? Email { get; set; } = null;

        [StringLength(20)]
        public string? PhoneNumber { get; set; } = null;

        [StringLength(50)]
        public string? Username { get; set; } = null;

        [StringLength(100)]
        public string? PasswordHash { get; set; } = null;

        public DateTime? PasswordUpdateDate { get; set; }

        [ForeignKey("Role")]
        public int RoleId { get; set; } = 2; // Default to User role
        public Role Role { get; set; }

        public byte[]? Picture { get; set; }


        // information about the user
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime UpdateDate { get; set; } = DateTime.UtcNow;

        public DateTime? LastLogin { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime? DeactivationDate { get; set; }

        // Navigation properties

        public virtual ICollection<Rental> Rentals { get; set; }
        public virtual ICollection<Review> Reviews { get; set; }
        public virtual ICollection<PaymentTransaction> PaymentTransactions { get; set; }
        public virtual ICollection<Cart> Carts { get; set; }
        public virtual ICollection<Order> Orders { get; set; }
        public virtual ICollection<Notification> Notifications { get; set; }
        public virtual ICollection<UserFavorite> Favorites { get; set; }
        public virtual ICollection<ToolDamageReport> ReportedDamages { get; set; }
        public virtual ICollection<ToolMaintenanceSchedule> AssignedMaintenance { get; set; }

        // Logging properties
        [NotMapped]
        public string EntityName => "User";

        [NotMapped]
        public string FullName => $"{FirstName} {LastName}";
    }
}
