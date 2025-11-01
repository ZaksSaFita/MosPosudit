using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Requests.Tool;
using MosPosudit.Model.Responses.Tool;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class ToolService : BaseCrudService<ToolResponse, ToolSearchObject, Tool, ToolInsertRequest, ToolUpdateRequest>, IToolService
    {
        public ToolService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Tool> ApplyFilter(IQueryable<Tool> query, ToolSearchObject search)
        {
            query = query.Include(t => t.Category);

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(x => x.Name != null && x.Name.Contains(search.Name));

            if (search.CategoryId.HasValue)
                query = query.Where(x => x.CategoryId == search.CategoryId.Value);

            if (search.IsAvailable.HasValue)
                query = query.Where(x => x.IsAvailable == search.IsAvailable.Value);

            return query;
        }

        public override async Task<ToolResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<Tool>()
                .Include(t => t.Category)
                .FirstOrDefaultAsync(t => t.Id == id);
            
            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected override ToolResponse MapToResponse(Tool entity)
        {
            var response = _mapper.Map<ToolResponse>(entity);
            response.CategoryName = entity.Category?.Name;
            return response;
        }

        protected override async Task BeforeInsert(Tool entity, ToolInsertRequest request)
        {
            entity.IsAvailable = request.IsAvailable;
        }
    }
}
