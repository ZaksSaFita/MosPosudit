using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Message
{
    public class MessageSendRequest
    {
        [Required(ErrorMessage = "Content is required")]
        public string Content { get; set; } = string.Empty;
    }
}

