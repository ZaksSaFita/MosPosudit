using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MošPosudit.Services.DataBase.Data
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        public string FirstName { get; set; }

        [Required]
        [StringLength(50)]
        public string LastName { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(100)]
        public string Email { get; set; }

        [Required]
        [StringLength(20)]
        public string PhoneNumber { get; set; }

        [Required]
        [StringLength(100)]
        public string Address { get; set; }

        [Required]
        [StringLength(50)]
        public string Username { get; set; }

        [Required]
        [StringLength(100)]
        public string Password { get; set; }

        [Required]
        public int RoleId { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        public DateTime? LastLogin { get; set; }

        [Required]
        public bool IsActive { get; set; }

        // Navigation properties
        public Role Role { get; set; }
        public ICollection<Rental> Rentals { get; set; }
        public ICollection<Review> Reviews { get; set; }
        public ICollection<PaymentTransaction> PaymentTransactions { get; set; }
        public ICollection<Cart> Carts { get; set; }
        public ICollection<Order> Orders { get; set; }
        public ICollection<Notification> Notifications { get; set; }
        public ICollection<UserFavorite> Favorites { get; set; }
        public ICollection<ToolDamageReport> ReportedDamages { get; set; }
        public ICollection<ToolMaintenanceSchedule> AssignedMaintenance { get; set; }

        // Logging properties
        [NotMapped]
        public string EntityName => "User";

        [NotMapped]
        public string FullName => $"{FirstName} {LastName}";
    }
} 