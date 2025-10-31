using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MosPosudit.Services.DataBase.Data
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        public string? FirstName { get; set; }

        public string? LastName { get; set; }

        public string? Email { get; set; }

        public string? PhoneNumber { get; set; }

        public string? Username { get; set; }

        public string? PasswordHash { get; set; }

        public DateTime? PasswordUpdateDate { get; set; }

        [ForeignKey("Role")]
        public int RoleId { get; set; }
        public Role Role { get; set; } = null!;

        public byte[]? Picture { get; set; }


        // information about the user
        public DateTime CreatedAt { get; set; }

        public DateTime UpdateDate { get; set; }

        public DateTime? LastLogin { get; set; }

        public bool IsActive { get; set; }

        public DateTime? DeactivationDate { get; set; }

        // Navigation properties

        public virtual ICollection<Rental> Rentals { get; set; } = new List<Rental>();
        public virtual ICollection<PaymentTransaction> PaymentTransactions { get; set; } = new List<PaymentTransaction>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<UserFavorite> Favorites { get; set; } = new List<UserFavorite>();
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public virtual ICollection<Message> SentMessages { get; set; } = new List<Message>();
        public virtual ICollection<Message> ReceivedMessages { get; set; } = new List<Message>();
        public virtual ICollection<Message> StartedChats { get; set; } = new List<Message>();

        [NotMapped]
        public string FullName => $"{FirstName} {LastName}";
    }
}
