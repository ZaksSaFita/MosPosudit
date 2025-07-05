using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Auth
{
    public class LoginRequest
    {
        [Required(ErrorMessage = "Username is required")]
        public string Username { get; set; }

        [Required(ErrorMessage = "Password is required")]
        public string Password { get; set; }
    }
} 
