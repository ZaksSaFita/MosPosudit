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

        public async Task<ToolAvailabilityResponse?> GetAvailabilityAsync(int toolId, DateTime startDate, DateTime endDate)
        {
            var tool = await _context.Set<Tool>()
                .FirstOrDefaultAsync(t => t.Id == toolId);

            if (tool == null)
                return null;

            // tool.Quantity represents the original stock quantity and doesn't change when orders are created
            // We can use it directly as the total available quantity
            int totalQuantity = tool.Quantity;

            var response = new ToolAvailabilityResponse
            {
                ToolId = toolId,
                TotalQuantity = totalQuantity,
                DailyAvailability = new Dictionary<string, int>()
            };

            // Normalize dates (remove time component)
            startDate = startDate.Date;
            endDate = endDate.Date;

            // Get all active orders (not returned) that overlap with the date range
            // An order overlaps if:
            // - Order starts before or during the requested period AND
            // - Order ends after or during the requested period
            var overlappingOrders = await _context.Set<Order>()
                .Include(o => o.OrderItems)
                .Where(o => 
                    !o.IsReturned && // Not returned yet
                    o.StartDate.Date <= endDate && // Order starts before/at end of requested period
                    o.EndDate.Date >= startDate && // Order ends after/at start of requested period
                    o.OrderItems.Any(oi => oi.ToolId == toolId)) // Contains this tool
                .ToListAsync();

            // For each day in the requested range, calculate rented quantity
            var currentDate = startDate;
            while (currentDate <= endDate)
            {
                var dateKey = currentDate.ToString("yyyy-MM-dd");
                int rentedQuantity = 0;

                // Find all orders that overlap with this specific day
                foreach (var order in overlappingOrders)
                {
                    // Check if order overlaps with current day
                    if (order.StartDate.Date <= currentDate && order.EndDate.Date >= currentDate)
                    {
                        // Get quantity rented for this tool in this order
                        var orderItem = order.OrderItems.FirstOrDefault(oi => oi.ToolId == toolId);
                        if (orderItem != null)
                        {
                            rentedQuantity += orderItem.Quantity;
                        }
                    }
                }

                // Available quantity = total stock - rented
                var availableQuantity = Math.Max(0, totalQuantity - rentedQuantity);
                response.DailyAvailability[dateKey] = availableQuantity;

                // Move to next day
                currentDate = currentDate.AddDays(1);
            }

            return response;
        }
    }
}
