using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Message
{
    public class MessageInsertRequest
    {
        [Required]
        public int FromUserId { get; set; }

        public int? ToUserId { get; set; }

        [Required]
        [StringLength(5000)]
        public string Content { get; set; } = string.Empty;
    }
}

