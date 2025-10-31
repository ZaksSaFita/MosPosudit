using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.User
{
    public class UserProfileUpdateRequest
    {
        [StringLength(50)]
        public string? FirstName { get; set; }

        [StringLength(50)]
        public string? LastName { get; set; }

        [StringLength(50)]
        public string? Username { get; set; }

        [StringLength(100)]
        [EmailAddress(ErrorMessage = "Invalid email format")]
        public string? Email { get; set; }

        [StringLength(20)]
        [Phone]
        public string? PhoneNumber { get; set; }

        public byte[]? Picture { get; set; }
    }
} 