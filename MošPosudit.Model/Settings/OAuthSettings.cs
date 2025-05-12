namespace MošPosudit.Model.Settings
{
    public class OAuthSettings
    {
        public GoogleSettings Google { get; set; }
        public MicrosoftSettings Microsoft { get; set; }
        public FacebookSettings Facebook { get; set; }
    }

    public class GoogleSettings
    {
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
    }

    public class MicrosoftSettings
    {
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
    }

    public class FacebookSettings
    {
        public string AppId { get; set; }
        public string AppSecret { get; set; }
    }
} 