namespace MošPosudit.Model.Enums
{
    public enum RentalStatus
    {
        Pending,
        Active,
        Completed,
        Cancelled,
        Overdue,
        Returned,
        Damaged
    }

    public enum OrderStatus
    {
        Pending,
        Confirmed,
        Processing,
        Shipped,
        Delivered,
        Cancelled,
        Returned
    }

    public enum RepairStatus
    {
        Pending,
        InProgress,
        Completed,
        Cancelled,
        PartsOrdered,
        AwaitingParts
    }
} 