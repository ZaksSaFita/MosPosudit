using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.UserFavorite
{
    public class UserFavoriteInsertRequest
    {
        [Required(ErrorMessage = "Tool ID is required")]
        public int ToolId { get; set; }

        // UserId will be set from authenticated user context
        public int UserId { get; set; }
    }
}

