namespace MošPosudit.Model.Enums
{
    public enum LogLevel
    {
        Debug,
        Info,
        Warning,
        Error,
        Critical
    }

    public enum LogAction
    {
        Create,
        Read,
        Update,
        Delete,
        Login,
        Logout,
        Register,
        PasswordChange,
        PasswordReset,
        EmailVerification,
        PaymentProcessed,
        PaymentRefunded,
        RentalCreated,
        RentalReturned,
        ToolMaintenance,
        ToolDamageReported,
        ReviewPosted,
        ReviewUpdated,
        ReviewDeleted,
        CategoryCreated,
        CategoryUpdated,
        CategoryDeleted,
        UserActivated,
        UserDeactivated,
        RoleChanged,
        SettingsUpdated,
        SystemBackup,
        SystemRestore,
        ErrorOccurred,
        SecurityViolation,
        DataExport,
        DataImport
    }
} 