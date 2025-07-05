namespace MosPosudit.Model.Responses.Auth
{
    public class LoginResponse
    {
        public string Token { get; set; } = string.Empty;
        public int? UserId { get; set; }
    }
} 