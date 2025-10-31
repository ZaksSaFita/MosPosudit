using MosPosudit.Model.Requests.Tool;
using MosPosudit.Model.Responses.Tool;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase.Data;

namespace MosPosudit.Services.Interfaces
{
    public interface IToolService : ICrudService<Tool, ToolSearchObject, ToolInsertRequest, ToolUpdateRequest, ToolPatchRequest>
    {
        Task<IEnumerable<ToolResponse>> GetAsResponse(ToolSearchObject? search = null);
        Task<ToolResponse> GetByIdAsResponse(int id);
        Task<ToolResponse> InsertAsResponse(ToolInsertRequest insert);
        Task<ToolResponse> UpdateAsResponse(int id, ToolUpdateRequest update);
        Task<ToolResponse> PatchAsResponse(int id, ToolPatchRequest patch);
        Task<ToolResponse> DeleteAsResponse(int id);
        ToolResponse MapToResponse(Tool entity);
    }
}

