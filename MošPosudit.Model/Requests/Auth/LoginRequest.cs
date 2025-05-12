using System.ComponentModel.DataAnnotations;

namespace MošPosudit.Model.Requests.Auth
{
    public class LoginRequest
    {
        [Required(ErrorMessage = "Username is required")]
        public string Username { get; set; }

        [Required(ErrorMessage = "Password is required")]
        public string Password { get; set; }
    }
} 