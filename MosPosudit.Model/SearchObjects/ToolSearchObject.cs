namespace MosPosudit.Model.SearchObjects
{
    public class ToolSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CategoryId { get; set; }
        public bool? IsAvailable { get; set; }
    }
}

