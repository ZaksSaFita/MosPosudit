namespace MošPosudit.Model.Messages
{
    public static class ErrorMessages
    {
        // User related errors
        public const string UserNotFound = "User not found";
        public const string InvalidCredentials = "Invalid username or password";
        public const string EmailAlreadyExists = "Email already exists";
        public const string UsernameAlreadyExists = "Username already exists";
        public const string InvalidEmail = "Invalid email format";
        public const string InvalidPhoneNumber = "Invalid phone number format";
        public const string RequiredField = "This field is required";
        public const string InvalidLength = "Invalid field length";
        public const string UserDeactivated = "User account is deactivated";
        public const string PasswordTooWeak = "Password must be at least 8 characters long and contain at least one number and one special character";
        public const string InvalidPassword = "Invalid password format";
        public const string UsernameExists = "Username already exists.";
        public const string EmailExists = "Email already exists.";

        // Tool related errors
        public const string ToolNotFound = "Tool not found";
        public const string ToolNotAvailable = "Tool is not available for rent";
        public const string ToolAlreadyRented = "Tool is already rented";
        public const string InvalidToolPrice = "Invalid tool price";
        public const string ToolNameExists = "Tool with this name already exists";
        public const string InvalidToolQuantity = "Invalid tool quantity";
        public const string ToolInMaintenance = "Tool is currently in maintenance";

        // Rental related errors
        public const string RentalNotFound = "Rental not found";
        public const string InvalidRentalDates = "Invalid rental dates";
        public const string RentalAlreadyExists = "Rental already exists for these dates";
        public const string RentalNotActive = "Rental is not active";
        public const string RentalAlreadyCompleted = "Rental is already completed";
        public const string RentalAlreadyCancelled = "Rental is already cancelled";
        public const string InvalidRentalStatus = "Invalid rental status";

        // Payment related errors
        public const string PaymentNotFound = "Payment not found";
        public const string PaymentFailed = "Payment failed";
        public const string InvalidPaymentAmount = "Invalid payment amount";
        public const string PaymentAlreadyProcessed = "Payment is already processed";
        public const string InvalidPaymentMethod = "Invalid payment method";
        public const string PaymentNotAuthorized = "Payment not authorized";

        // Category related errors
        public const string CategoryNotFound = "Category not found";
        public const string CategoryNameExists = "Category with this name already exists";
        public const string CategoryHasTools = "Cannot delete category that has tools";

        // Review related errors
        public const string ReviewNotFound = "Review not found";
        public const string InvalidRating = "Rating must be between 1 and 5";
        public const string ReviewAlreadyExists = "Review already exists for this rental";

        // Maintenance related errors
        public const string MaintenanceNotFound = "Maintenance record not found";
        public const string InvalidMaintenanceDate = "Invalid maintenance date";
        public const string ToolNotInMaintenance = "Tool is not in maintenance";

        // General errors
        public const string Unauthorized = "Unauthorized access";
        public const string Forbidden = "Access forbidden";
        public const string ServerError = "Internal server error";
        public const string InvalidRequest = "Invalid request";
        public const string ValidationError = "Validation error";
        public const string DatabaseError = "Database error";
        public const string FileNotFound = "File not found";
        public const string InvalidFileFormat = "Invalid file format";
        public const string FileTooLarge = "File is too large";
    }
} 