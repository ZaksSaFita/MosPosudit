using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.User
{
    public class UserInsertRequest
    {
        [StringLength(50, ErrorMessage = "First name cannot be longer than 50 characters")]
        public string? FirstName { get; set; }

        [StringLength(50, ErrorMessage = "Last name cannot be longer than 50 characters")]
        public string? LastName { get; set; }

        [StringLength(50, ErrorMessage = "Username cannot be longer than 50 characters")]
        public string? Username { get; set; }

        [EmailAddress(ErrorMessage = "Invalid email format")]
        [StringLength(100, ErrorMessage = "Email cannot be longer than 100 characters")]
        public string? Email { get; set; }

        [StringLength(20, ErrorMessage = "Phone number cannot be longer than 20 characters")]
        [Phone(ErrorMessage = "Invalid phone number format")]
        public string? PhoneNumber { get; set; }

        [StringLength(100, ErrorMessage = "Password cannot be longer than 100 characters")]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long")]
        public string? Password { get; set; }

        public byte[]? Picture { get; set; }

        public int RoleId { get; set; }
    }
}
