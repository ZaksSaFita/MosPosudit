using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.User
{
    public class UserRegisterRequest
    {
        [Required]
        [StringLength(50)]
        public required string FirstName { get; set; }

        [Required]
        [StringLength(50)]
        public required string LastName { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(100)]
        public required string Email { get; set; }

        [Required]
        [StringLength(20)]
        [Phone]
        public required string PhoneNumber { get; set; }



        [Required]
        [StringLength(50)]
        public required string Username { get; set; }

        [Required]
        [StringLength(100)]
        [MinLength(8)]
        public required string Password { get; set; }
    }
}
