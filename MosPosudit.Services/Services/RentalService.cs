using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Enums;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Requests.Rental;
using MosPosudit.Model.Responses.Rental;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class RentalService : BaseCrudService<Rental, RentalSearchObject, RentalInsertRequest, RentalUpdateRequest, RentalPatchRequest>, IRentalService
    {
        public RentalService(ApplicationDbContext context) : base(context)
        {
        }

        public override async Task<IEnumerable<Rental>> Get(RentalSearchObject? search = null)
        {
            var query = _dbSet
                .Include(r => r.User)
                .Include(r => r.Status)
                .Include(r => r.RentalItems)
                    .ThenInclude(ri => ri.Tool)
                .AsQueryable();

            if (search != null)
            {
                if (search.UserId.HasValue)
                    query = query.Where(r => r.UserId == search.UserId.Value);

                if (search.ToolId.HasValue)
                    query = query.Where(r => r.RentalItems.Any(ri => ri.ToolId == search.ToolId.Value));

                if (search.StatusId.HasValue)
                    query = query.Where(r => r.StatusId == search.StatusId.Value);

                if (search.StartDateFrom.HasValue)
                    query = query.Where(r => r.StartDate >= search.StartDateFrom.Value);

                if (search.StartDateTo.HasValue)
                    query = query.Where(r => r.StartDate <= search.StartDateTo.Value);

                if (search.EndDateFrom.HasValue)
                    query = query.Where(r => r.EndDate >= search.EndDateFrom.Value);

                if (search.EndDateTo.HasValue)
                    query = query.Where(r => r.EndDate <= search.EndDateTo.Value);

                if (search.IsReturned.HasValue)
                    query = query.Where(r => r.IsReturned == search.IsReturned.Value);

                if (search.IsActive.HasValue)
                {
                    if (search.IsActive.Value)
                        query = query.Where(r => (r.StatusId == (int)RentalStatus.Pending || r.StatusId == (int)RentalStatus.Active) && !r.IsReturned);
                    else
                        query = query.Where(r => r.StatusId != (int)RentalStatus.Pending && r.StatusId != (int)RentalStatus.Active || r.IsReturned);
                }
            }

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                            .Take(search.PageSize.Value);
            }

            return await query.ToListAsync();
        }

        public override async Task<Rental> GetById(int id)
        {
            if (id <= 0)
                throw new ValidationException("Invalid rental ID");

            var rental = await _dbSet
                .Include(r => r.User)
                .Include(r => r.Status)
                .Include(r => r.RentalItems)
                    .ThenInclude(ri => ri.Tool)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (rental == null)
                throw new NotFoundException("Rental not found");

            return rental;
        }

        public override async Task<Rental> Insert(RentalInsertRequest insert)
        {
            if (insert == null)
                throw new ValidationException("Invalid request");

            if (insert.StartDate >= insert.EndDate)
                throw new ValidationException("Start date must be before end date");

            if (insert.Items == null || insert.Items.Count == 0)
                throw new ValidationException("At least one rental item is required");

            // Check availability for each tool
            foreach (var item in insert.Items)
            {
                var isAvailable = await CheckAvailability(item.ToolId, insert.StartDate, insert.EndDate);
                if (!isAvailable)
                {
                    var tool = await _context.Tools.FindAsync(item.ToolId);
                    throw new ValidationException($"Tool '{tool?.Name ?? item.ToolId.ToString()}' is not available for the selected dates");
                }

                // Verify tool exists and get current daily rate
                var toolEntity = await _context.Tools.FindAsync(item.ToolId);
                if (toolEntity == null)
                    throw new NotFoundException($"Tool with ID {item.ToolId} not found");

                // Update daily rate from tool if not provided or different
                if (item.DailyRate != toolEntity.DailyRate)
                {
                    // Use tool's daily rate
                    item.DailyRate = toolEntity.DailyRate;
                }
            }

            // Calculate total price
            var totalDays = (insert.EndDate - insert.StartDate).Days + 1;
            var totalPrice = insert.Items.Sum(item => item.DailyRate * item.Quantity * totalDays);

            // Create rental entity - use first tool's ID for legacy ToolId field
            // Note: Rental model has both ToolId (legacy) and RentalItems (current approach)
            var rental = new Rental
            {
                UserId = insert.UserId, // Should be set from authenticated user context
                StartDate = insert.StartDate,
                EndDate = insert.EndDate,
                StatusId = (int)RentalStatus.Pending, // Default to Pending, admin will approve
                ToolId = insert.Items.First().ToolId, // Legacy field - use first item
                TotalPrice = totalPrice,
                TotalAmount = totalPrice,
                Notes = insert.Notes,
                CreatedAt = DateTime.UtcNow,
                IsReturned = false,
                RentalItems = insert.Items.Select(item => new RentalItem
                {
                    ToolId = item.ToolId,
                    Quantity = item.Quantity,
                    DailyRate = item.DailyRate,
                    Notes = item.Notes
                }).ToList()
            };

            await _dbSet.AddAsync(rental);
            await _context.SaveChangesAsync();

            // Reload with includes
            return await GetById(rental.Id);
        }

        public async Task<IEnumerable<RentalResponse>> GetAsResponse(RentalSearchObject? search = null)
        {
            var entities = await Get(search);
            return entities.Select(MapToResponse);
        }

        public async Task<RentalResponse> GetByIdAsResponse(int id)
        {
            var entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<RentalResponse> InsertAsResponse(RentalInsertRequest insert)
        {
            var entity = await Insert(insert);
            // Entity is already reloaded with includes in Insert method
            return MapToResponse(entity);
        }

        public async Task<RentalResponse> UpdateAsResponse(int id, RentalUpdateRequest update)
        {
            var entity = await Update(id, update);
            // Reload with includes for MapToResponse
            entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<RentalResponse> PatchAsResponse(int id, RentalPatchRequest patch)
        {
            var entity = await Patch(id, patch);
            // Reload with includes for MapToResponse
            entity = await GetById(id);
            return MapToResponse(entity);
        }

        public async Task<RentalResponse> DeleteAsResponse(int id)
        {
            var entity = await GetById(id);
            var response = MapToResponse(entity);
            await Delete(id);
            return response;
        }

        public async Task<IEnumerable<RentalResponse>> GetByUserId(int userId)
        {
            var search = new RentalSearchObject { UserId = userId };
            var rentals = await Get(search);
            return rentals.Select(MapToResponse);
        }

        public async Task<bool> CheckAvailability(int toolId, DateTime startDate, DateTime endDate)
        {
            // Check if tool exists and is available
            var tool = await _context.Tools.FindAsync(toolId);
            if (tool == null || !tool.IsAvailable)
                return false;

            // Check for overlapping rentals that are pending or active
            // Check through RentalItems since rental can have multiple tools
            var overlappingRentals = await _context.Rentals
                .Include(r => r.RentalItems)
                .Where(r => !r.IsReturned &&
                           (r.StatusId == (int)RentalStatus.Pending || r.StatusId == (int)RentalStatus.Active) &&
                           ((r.StartDate <= startDate && r.EndDate >= startDate) ||
                            (r.StartDate <= endDate && r.EndDate >= endDate) ||
                            (r.StartDate >= startDate && r.EndDate <= endDate)) &&
                           r.RentalItems.Any(ri => ri.ToolId == toolId))
                .ToListAsync();

            // Check total quantity needed vs available
            var totalRentedQuantity = overlappingRentals
                .SelectMany(r => r.RentalItems)
                .Where(ri => ri.ToolId == toolId)
                .Sum(ri => ri.Quantity);

            // Tool is available if total rented quantity is less than tool quantity
            return totalRentedQuantity < tool.Quantity;
        }

        public async Task<IEnumerable<DateTime>> GetBookedDates(int toolId, DateTime startDate, DateTime endDate)
        {
            var bookedDates = new List<DateTime>();

            // Check through RentalItems since rental can have multiple tools
            var overlappingRentals = await _context.Rentals
                .Include(r => r.RentalItems)
                .Where(r => !r.IsReturned &&
                           (r.StatusId == (int)RentalStatus.Pending || r.StatusId == (int)RentalStatus.Active) &&
                           r.EndDate >= startDate &&
                           r.StartDate <= endDate &&
                           r.RentalItems.Any(ri => ri.ToolId == toolId))
                .ToListAsync();

            foreach (var rental in overlappingRentals)
            {
                // Get quantity for this specific tool in this rental
                var toolQuantity = rental.RentalItems
                    .Where(ri => ri.ToolId == toolId)
                    .Sum(ri => ri.Quantity);

                // Get tool total quantity
                var tool = await _context.Tools.FindAsync(toolId);
                if (tool != null && toolQuantity >= tool.Quantity)
                {
                    // Tool is fully booked for this rental period
                    var currentDate = rental.StartDate.Date;
                    var end = rental.EndDate.Date;

                    while (currentDate <= end)
                    {
                        if (currentDate >= startDate.Date && currentDate <= endDate.Date)
                        {
                            bookedDates.Add(currentDate);
                        }
                        currentDate = currentDate.AddDays(1);
                    }
                }
            }

            return bookedDates.Distinct();
        }

        public RentalResponse MapToResponse(Rental entity)
        {
            return new RentalResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UserName = entity.User != null ? $"{entity.User.FirstName} {entity.User.LastName}".Trim() : null,
                StartDate = entity.StartDate,
                EndDate = entity.EndDate,
                StatusId = entity.StatusId,
                StatusName = ((RentalStatus)entity.StatusId).ToString(),
                TotalPrice = entity.TotalPrice,
                TotalAmount = entity.TotalAmount,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt,
                Notes = entity.Notes,
                IsReturned = entity.IsReturned,
                ReturnDate = entity.ReturnDate,
                ReturnNotes = entity.ReturnNotes,
                Items = entity.RentalItems?.Select(ri => new RentalItemResponse
                {
                    Id = ri.Id,
                    RentalId = ri.RentalId,
                    ToolId = ri.ToolId,
                    ToolName = ri.Tool?.Name,
                    Quantity = ri.Quantity,
                    DailyRate = ri.DailyRate,
                    Notes = ri.Notes
                }).ToList() ?? new List<RentalItemResponse>()
            };
        }

        protected override Rental MapToEntity(RentalInsertRequest insert)
        {
            // This is handled in the overridden Insert method
            throw new NotImplementedException("Use the Insert method directly");
        }

        protected override void MapToEntity(RentalUpdateRequest update, Rental entity)
        {
            entity.StartDate = update.StartDate;
            entity.EndDate = update.EndDate;
            entity.StatusId = update.StatusId;
            entity.Notes = update.Notes;
            entity.UpdatedAt = DateTime.UtcNow;

            // Recalculate total if dates changed
            if (entity.RentalItems != null && entity.RentalItems.Any())
            {
                var totalDays = (update.EndDate - update.StartDate).Days + 1;
                entity.TotalPrice = entity.RentalItems.Sum(ri => ri.DailyRate * ri.Quantity * totalDays);
                entity.TotalAmount = entity.TotalPrice;
            }
        }

        protected override void MapToEntity(RentalPatchRequest patch, Rental entity)
        {
            if (patch.StartDate.HasValue)
                entity.StartDate = patch.StartDate.Value;
            if (patch.EndDate.HasValue)
                entity.EndDate = patch.EndDate.Value;
            if (patch.StatusId.HasValue)
                entity.StatusId = patch.StatusId.Value;
            if (patch.Notes != null)
                entity.Notes = patch.Notes;
            if (patch.IsReturned.HasValue)
                entity.IsReturned = patch.IsReturned.Value;
            if (patch.ReturnDate.HasValue)
                entity.ReturnDate = patch.ReturnDate;
            if (patch.ReturnNotes != null)
                entity.ReturnNotes = patch.ReturnNotes;

            entity.UpdatedAt = DateTime.UtcNow;

            // Recalculate total if dates changed
            if ((patch.StartDate.HasValue || patch.EndDate.HasValue) && entity.RentalItems != null && entity.RentalItems.Any())
            {
                var totalDays = ((patch.EndDate ?? entity.EndDate) - (patch.StartDate ?? entity.StartDate)).Days + 1;
                entity.TotalPrice = entity.RentalItems.Sum(ri => ri.DailyRate * ri.Quantity * totalDays);
                entity.TotalAmount = entity.TotalPrice;
            }
        }
    }
}

