namespace MosPosudit.Model.SearchObjects
{
    public class BaseSearchObject
    {
        public int? Page { get; set; }
        public int? PageSize { get; set; }
        public bool RetrieveAll { get; set; } = false;
        public bool IncludeTotalCount { get; set; } = false;
    }
} 
