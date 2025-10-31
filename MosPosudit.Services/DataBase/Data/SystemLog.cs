using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Services.DataBase.Data
{
    public class SystemLog
    {
        [Key]
        public int Id { get; set; }

        public DateTime Timestamp { get; set; }

        public string? LogLevel { get; set; } // INFO, WARNING, ERROR, DEBUG

        public string? Action { get; set; } // CREATE, UPDATE, DELETE, LOGIN, etc.

        public string? Entity { get; set; } // User, Tool, Rental, etc.

        public int? EntityId { get; set; } // ID of the affected entity

        public string? Message { get; set; }

        public string? Username { get; set; } // User who performed the action

        public string? IpAddress { get; set; }

        public string? AdditionalInfo { get; set; } // JSON string for additional data

        public string? StackTrace { get; set; } // For error logs

        public string? Details { get; set; }
    }
}
