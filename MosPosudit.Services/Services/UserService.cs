using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.Requests.User;
using MosPosudit.Model.Responses.User;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using MapsterMapper;

namespace MosPosudit.Services.Services
{
    public class UserService : BaseCrudService<UserResponse, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        public UserService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Username))
                query = query.Where(x => x.Username != null && x.Username.Contains(search.Username));

            if (!string.IsNullOrWhiteSpace(search.Email))
                query = query.Where(x => x.Email != null && x.Email.Contains(search.Email));

            return query;
        }

        public override async Task<UserResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<User>()
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        public override async Task<UserResponse> CreateAsync(UserInsertRequest request)
        {
            if (request.Username != null && await CheckUsernameExists(request.Username))
                throw new ConflictException(ErrorMessages.UsernameExists);

            if (request.Email != null && await CheckEmailExists(request.Email))
                throw new ConflictException(ErrorMessages.EmailExists);

            var now = DateTime.UtcNow;
            var entity = _mapper.Map<User>(request);
            entity.PasswordHash = !string.IsNullOrEmpty(request.Password) ? BCrypt.Net.BCrypt.HashPassword(request.Password) : null;
            entity.RoleId = request.RoleId > 0 ? request.RoleId : 2; // Default to User role (ID 2)
            entity.PasswordUpdateDate = !string.IsNullOrEmpty(request.Password) ? now : null;
            entity.CreatedAt = now;
            entity.UpdateDate = now;
            entity.IsActive = true;
            entity.DeactivationDate = null;

            _context.Set<User>().Add(entity);
            await _context.SaveChangesAsync();

            // Reload with includes
            return await GetByIdAsync(entity.Id) ?? throw new Exception("Failed to retrieve created user");
        }

        protected override async Task BeforeUpdate(User entity, UserUpdateRequest request)
        {
            if (request.Username != null && await CheckUsernameExists(request.Username) && entity.Username != request.Username)
                throw new ConflictException(ErrorMessages.UsernameExists);

            if (request.Email != null && await CheckEmailExists(request.Email) && entity.Email != request.Email)
                throw new ConflictException(ErrorMessages.EmailExists);

            entity.UpdateDate = DateTime.UtcNow;

            if (!string.IsNullOrEmpty(request.Password))
            {
                entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
                entity.PasswordUpdateDate = DateTime.UtcNow;
            }
        }

        protected override void MapUpdateToEntity(User entity, UserUpdateRequest request)
        {
            _mapper.Map(request, entity);
            if (request.RoleId > 0) entity.RoleId = request.RoleId;
            if (request.Picture != null) entity.Picture = request.Picture;
        }

        public async Task<IEnumerable<UserResponse>> GetNonAdminUsers()
        {
            var users = await _context.Set<User>()
                .Include(u => u.Role)
                .Where(x => x.RoleId != 1)
                .ToListAsync();
            return users.Select(MapToResponse);
        }

        public async Task<bool> DeactivateUser(int id)
        {
            var user = await _context.Set<User>().FindAsync(id);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            user.IsActive = false;
            user.DeactivationDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ActivateUser(int id)
        {
            var user = await _context.Set<User>().FindAsync(id);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            user.IsActive = true;
            user.DeactivationDate = null;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ChangePassword(int id, string currentPassword, string newPassword)
        {
            var user = await _context.Set<User>().FindAsync(id);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            if (user.PasswordHash == null || !BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
                throw new ValidationException(ErrorMessages.InvalidCredentials);

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.PasswordUpdateDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> VerifyCurrentPassword(int id, string currentPassword)
        {
            var user = await _context.Set<User>().FindAsync(id);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            return user.PasswordHash != null && BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash);
        }

        public async Task<bool> SendPasswordResetEmail(string email)
        {
            var user = await _context.Set<User>().FirstOrDefaultAsync(x => x.Email == email);
            if (user == null)
                return false; // Don't reveal if email exists or not

            // In a real application, you would:
            // 1. Generate a secure reset token
            // 2. Store it in database with expiration
            // 3. Send email with reset link
            // For now, we'll just return true to simulate success

            return true;
        }

        public async Task<UserResponse> UpdateProfile(int userId, UserProfileUpdateRequest request)
        {
            var user = await _context.Set<User>().Include(u => u.Role).FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            // Validate username uniqueness
            if (request.Username != null)
            {
                var usernameExists = await _context.Set<User>().AnyAsync(x =>
                    x.Username != null && x.Username.ToLower() == request.Username.ToLower() && x.Id != userId);
                if (usernameExists)
                    throw new ConflictException(ErrorMessages.UsernameExists);
            }

            // Validate email uniqueness
            if (request.Email != null)
            {
                var emailExists = await _context.Set<User>().AnyAsync(x =>
                    x.Email != null && x.Email.ToLower() == request.Email.ToLower() && x.Id != userId);
                if (emailExists)
                    throw new ConflictException(ErrorMessages.EmailExists);
            }

            // Update fields
            if (request.FirstName != null) user.FirstName = request.FirstName;
            if (request.LastName != null) user.LastName = request.LastName;
            if (request.Username != null) user.Username = request.Username;
            if (request.Email != null) user.Email = request.Email;
            if (request.PhoneNumber != null) user.PhoneNumber = request.PhoneNumber;
            if (request.Picture != null) user.Picture = request.Picture;

            user.UpdateDate = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return MapToResponse(user);
        }

        public async Task<bool> CheckUsernameExists(string username)
        {
            return await _context.Set<User>().AnyAsync(x => x.Username == username);
        }

        public async Task<bool> CheckEmailExists(string email)
        {
            return await _context.Set<User>().AnyAsync(x => x.Email == email);
        }

        public async Task<IEnumerable<UserResponse>> GetActiveUsers()
        {
            var users = await _context.Set<User>()
                .Include(u => u.Role)
                .Where(x => x.IsActive)
                .ToListAsync();
            return users.Select(MapToResponse);
        }

        public async Task<IEnumerable<UserResponse>> GetInactiveUsers()
        {
            var users = await _context.Set<User>()
                .Include(u => u.Role)
                .Where(x => !x.IsActive)
                .ToListAsync();
            return users.Select(MapToResponse);
        }

        public async Task<UserResponse> GetUserDetails(int id)
        {
            return await GetByIdAsync(id) ?? throw new NotFoundException(ErrorMessages.EntityNotFound);
        }

        public async Task<UserResponse> GetMe(int userId)
        {
            return await GetByIdAsync(userId) ?? throw new NotFoundException(ErrorMessages.EntityNotFound);
        }

        public async Task<UserResponse> UploadPicture(int userId, byte[] picture)
        {
            var user = await _context.Set<User>().Include(u => u.Role).FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            user.Picture = picture;
            user.UpdateDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        public async Task<bool> DeletePicture(int userId)
        {
            var user = await _context.Set<User>().FindAsync(userId);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            user.Picture = null;
            user.UpdateDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<UserResponse> Register(UserRegisterRequest request)
        {
            // Convert RegisterRequest to InsertRequest with default User role
            var insertRequest = new UserInsertRequest
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                Username = request.Username,
                Password = request.Password,
                RoleId = 2 // Default to User role (ID 2)
            };

            return await CreateAsync(insertRequest);
        }

        protected override UserResponse MapToResponse(User entity)
        {
            var response = _mapper.Map<UserResponse>(entity);
            response.Picture = entity.Picture != null ? Convert.ToBase64String(entity.Picture) : null;
            response.RoleName = entity.Role?.Name;
            return response;
        }
    }
}
