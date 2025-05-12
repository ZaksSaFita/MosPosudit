using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Model.Requests.User
{
    public class UserPatchRequest
    {
        [StringLength(50)]
        public string? FirstName { get; set; }

        [StringLength(50)]
        public string? LastName { get; set; }

        [EmailAddress]
        [StringLength(100)]
        public string? Email { get; set; }

        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        [StringLength(100)]
        public string? Address { get; set; }
    }
} 