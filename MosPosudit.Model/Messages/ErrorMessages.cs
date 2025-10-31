namespace MosPosudit.Model.Messages
{
    public static class ErrorMessages
    {
        // Base class errors
        public const string EntityNotFound = "Entity not found";

        // User related errors
        public const string InvalidCredentials = "Invalid username or password";
        public const string InvalidEmail = "Invalid email format";
        public const string UserDeactivated = "User account is deactivated";
        public const string UsernameExists = "Username already exists.";
        public const string EmailExists = "Email already exists.";

        // General errors
        public const string ServerError = "Internal server error";
        public const string InvalidRequest = "Invalid request";
    }
} 
