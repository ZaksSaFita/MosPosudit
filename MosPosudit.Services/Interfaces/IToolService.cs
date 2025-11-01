using MosPosudit.Model.Requests.Tool;
using MosPosudit.Model.Responses.Tool;
using MosPosudit.Model.SearchObjects;

namespace MosPosudit.Services.Interfaces
{
    public interface IToolService : ICrudService<ToolResponse, ToolSearchObject, ToolInsertRequest, ToolUpdateRequest>
    {
    }
}

