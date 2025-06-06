namespace MošPosudit.Model.Responses.Auth
{
    public class OAuthResponse
    {
        public int UserId { get; set; }
        public string? Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Role { get; set; }
        public bool IsNewUser { get; set; }
    }
}