using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Services.DataBase.Data
{
    public class SystemLog
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public DateTime Timestamp { get; set; }

        [Required]
        [StringLength(50)]
        public string? LogLevel { get; set; } // INFO, WARNING, ERROR, DEBUG

        [Required]
        [StringLength(100)]
        public string? Action { get; set; } // CREATE, UPDATE, DELETE, LOGIN, etc.

        [Required]
        [StringLength(100)]
        public string? Entity { get; set; } // User, Tool, Rental, etc.

        public int? EntityId { get; set; } // ID of the affected entity

        [StringLength(500)]
        public string? Message { get; set; }

        [StringLength(100)]
        public string? Username { get; set; } // User who performed the action

        [StringLength(50)]
        public string? IpAddress { get; set; }

        [StringLength(500)]
        public string? AdditionalInfo { get; set; } // JSON string for additional data

        [StringLength(500)]
        public string? StackTrace { get; set; } // For error logs

        [StringLength(500)]
        public string? Details { get; set; }
    }
}
