using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        public string? FirstName { get; set; }

        [Required]
        [StringLength(50)]
        public string? LastName { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(100)]
        public string? Email { get; set; }

        [Required]
        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        [Required]
        [StringLength(100)]
        public string? Address { get; set; }

        [Required]
        [StringLength(50)]
        public string? Username { get; set; }

        [Required]
        [StringLength(100)]
        public string? PasswordHash { get; set; }

        [Required]
        public DateTime PasswordUpdateDate { get; set; }

        [Required]
        [ForeignKey("Role")]
        public int RoleId { get; set; }
        public Role Role { get; set; }



        // information about the user
        [Required]
        public DateTime CreatedAt { get; set; }

        [Required]
        public DateTime UpdateDate { get; set; }

        public DateTime? LastLogin { get; set; }

        [Required]
        public bool IsActive { get; set; }

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
