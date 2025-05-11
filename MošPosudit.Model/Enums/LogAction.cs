namespace MošPosudit.Model.Enums
{
    public enum LogAction
    {
        // User actions
        UserLogin,
        UserLogout,
        UserRegister,
        UserUpdate,
        UserDelete,
        UserActivate,
        UserDeactivate,
        PasswordChange,

        // Tool actions
        ToolCreate,
        ToolUpdate,
        ToolDelete,
        ToolActivate,
        ToolDeactivate,
        ToolRent,
        ToolReturn,
        ToolMaintenance,

        // Rental actions
        RentalCreate,
        RentalUpdate,
        RentalDelete,
        RentalCancel,
        RentalComplete,
        RentalExtend,

        // Payment actions
        PaymentProcess,
        PaymentRefund,
        PaymentCancel,

        // Category actions
        CategoryCreate,
        CategoryUpdate,
        CategoryDelete,

        // Review actions
        ReviewCreate,
        ReviewUpdate,
        ReviewDelete,

        // System actions
        SystemStart,
        SystemStop,
        DatabaseBackup,
        DatabaseRestore,
        ConfigurationChange,
        ErrorOccurred
    }
} 