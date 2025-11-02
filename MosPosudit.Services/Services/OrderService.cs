using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Requests.Order;
using MosPosudit.Model.Responses.Order;
using MosPosudit.Model.Responses.Payment;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class OrderService : BaseCrudService<OrderResponse, OrderSearchObject, Order, OrderInsertRequest, OrderUpdateRequest>, IOrderService
    {
        public OrderService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Order> ApplyFilter(IQueryable<Order> query, OrderSearchObject search)
        {
            query = query.Include(o => o.User)
                         .Include(o => o.OrderItems)
                            .ThenInclude(oi => oi.Tool)
                         .Include(o => o.Payments);

            if (search.UserId.HasValue)
                query = query.Where(x => x.UserId == search.UserId.Value);

            if (search.StartDateFrom.HasValue)
                query = query.Where(x => x.StartDate >= search.StartDateFrom.Value);

            if (search.StartDateTo.HasValue)
                query = query.Where(x => x.StartDate <= search.StartDateTo.Value);

            if (search.EndDateFrom.HasValue)
                query = query.Where(x => x.EndDate >= search.EndDateFrom.Value);

            if (search.EndDateTo.HasValue)
                query = query.Where(x => x.EndDate <= search.EndDateTo.Value);

            if (search.IsReturned.HasValue)
                query = query.Where(x => x.IsReturned == search.IsReturned.Value);

            if (search.TermsAccepted.HasValue)
                query = query.Where(x => x.TermsAccepted == search.TermsAccepted.Value);

            return query;
        }

        public override async Task<OrderResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<Order>()
                .Include(o => o.User)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Tool)
                .Include(o => o.Payments)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected override OrderResponse MapToResponse(Order entity)
        {
            var response = _mapper.Map<OrderResponse>(entity);
            response.UserFullName = entity.User?.FullName;
            response.UserEmail = entity.User?.Email;
            response.OrderItems = entity.OrderItems.Select(oi => new OrderItemResponse
            {
                Id = oi.Id,
                OrderId = oi.OrderId,
                ToolId = oi.ToolId,
                ToolName = oi.Tool?.Name,
                Quantity = oi.Quantity,
                DailyRate = oi.DailyRate,
                TotalPrice = oi.TotalPrice
            }).ToList();
            response.Payments = entity.Payments.Select(p => new PaymentResponse
            {
                Id = p.Id,
                OrderId = p.OrderId,
                Amount = p.Amount,
                IsCompleted = p.IsCompleted,
                TransactionId = p.TransactionId,
                PaymentDate = p.PaymentDate,
                CreatedAt = p.CreatedAt
            }).ToList();
            return response;
        }

        protected override async Task BeforeInsert(Order entity, OrderInsertRequest request)
        {
            entity.CreatedAt = DateTime.UtcNow;
            entity.ConfirmationEmailSent = false;
            entity.IsReturned = false;

            // Calculate total amount from order items
            decimal totalAmount = 0;
            int days = (request.EndDate - request.StartDate).Days + 1;

            foreach (var itemRequest in request.OrderItems)
            {
                var tool = await _context.Set<Tool>().FindAsync(itemRequest.ToolId);
                if (tool == null)
                    continue;

                var dailyRate = tool.DailyRate;
                var itemTotalPrice = dailyRate * itemRequest.Quantity * days;

                var orderItem = new OrderItem
                {
                    ToolId = itemRequest.ToolId,
                    Quantity = itemRequest.Quantity,
                    DailyRate = dailyRate,
                    TotalPrice = itemTotalPrice
                };

                entity.OrderItems.Add(orderItem);
                totalAmount += itemTotalPrice;

                // Don't decrease tool quantity - availability is calculated based on orders, not fixed quantity
                // Quantity represents original stock and doesn't change when orders are created
                // Availability is calculated dynamically using GetAvailabilityAsync method
            }

            entity.TotalAmount = totalAmount;
        }

        protected override async Task BeforeUpdate(Order entity, OrderUpdateRequest request)
        {
            entity.UpdatedAt = DateTime.UtcNow;

            // If marking as returned, don't change tool quantities
            // Quantity represents original stock and doesn't change when orders are returned
            // Availability is calculated dynamically using GetAvailabilityAsync method
            if (request.IsReturned.HasValue && request.IsReturned.Value && !entity.IsReturned)
            {
                entity.IsReturned = true;
                entity.ReturnDate = request.ReturnDate ?? DateTime.UtcNow;

                // Don't change tool quantities - availability is calculated based on orders
                // When order is marked as returned, it's automatically excluded from availability calculations
            }
        }
    }
}

