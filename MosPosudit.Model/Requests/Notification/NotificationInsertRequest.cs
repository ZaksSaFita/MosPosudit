using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Notification
{
    public class NotificationInsertRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [StringLength(1000)]
        public string Message { get; set; } = string.Empty;

        [StringLength(50)]
        public string? Type { get; set; } = "Info";
    }
}

