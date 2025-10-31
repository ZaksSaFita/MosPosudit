using Microsoft.EntityFrameworkCore;
using MosPosudit.Model.Exceptions;
using MosPosudit.Model.Messages;
using MosPosudit.Model.Requests.User;
using MosPosudit.Model.Responses.User;
using MosPosudit.Model.SearchObjects;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    // User service implementation that handles user-specific operations
    public class UserService : BaseCrudService<User, UserSearchObject, UserInsertRequest, UserUpdateRequest, UserPatchRequest>, IUserService
    {
        public UserService(ApplicationDbContext context) : base(context)
        {
        }

        public override async Task<IEnumerable<User>> Get(UserSearchObject? search = null)
        {
            var query = _dbSet.AsQueryable();

            // Uklonjen filter za ne-admin korisnike

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Username))
                    query = query.Where(x => x.Username != null && x.Username.Contains(search.Username));

                if (!string.IsNullOrWhiteSpace(search.Email))
                    query = query.Where(x => x.Email != null && x.Email.Contains(search.Email));
            }

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                            .Take(search.PageSize.Value);
            }

            return await query.ToListAsync();
        }

        public override async Task<User> GetById(int id)
        {
            if (id <= 0)
                throw new ValidationException(ErrorMessages.InvalidRequest);

            var user = await _dbSet.Include(u => u.Role).FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
                throw new NotFoundException(ErrorMessages.EntityNotFound);

            return user;
        }

        public async Task<IEnumerable<User>> GetNonAdminUsers()
        {
            return await _dbSet.Where(x => x.RoleId != 1).ToListAsync();
        }

        public async Task<bool> DeactivateUser(int id)
        {
            var user = await GetById(id);
            user.IsActive = false;
            user.DeactivationDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ActivateUser(int id)
        {
            var user = await GetById(id);
            user.IsActive = true;
            user.DeactivationDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ChangePassword(int id, string currentPassword, string newPassword)
        {
            var user = await GetById(id);

            // Verify current password
            if (user.PasswordHash == null || !BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
                throw new ValidationException(ErrorMessages.InvalidCredentials);

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.PasswordUpdateDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> VerifyCurrentPassword(int id, string currentPassword)
        {
            var user = await GetById(id);
            return user.PasswordHash != null && BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash);
        }

        public async Task<bool> SendPasswordResetEmail(string email)
        {
            var user = await _dbSet.FirstOrDefaultAsync(x => x.Email == email);
            if (user == null)
                return false; // Don't reveal if email exists or not

            // In a real application, you would:
            // 1. Generate a secure reset token
            // 2. Store it in database with expiration
            // 3. Send email with reset link
            // For now, we'll just return true to simulate success

            return true;
        }

        public async Task<User> UpdateProfile(int userId, UserProfileUpdateRequest request)
        {
            var user = await GetById(userId);
            
            // Validate username uniqueness - case insensitive check
            if (request.Username != null)
            {
                var usernameExists = await _dbSet.AnyAsync(x => 
                    x.Username != null && x.Username.ToLower() == request.Username.ToLower() && x.Id != userId);
                if (usernameExists)
                    throw new ConflictException(ErrorMessages.UsernameExists);
            }
            
            // Validate email uniqueness - case insensitive check
            if (request.Email != null)
            {
                var emailExists = await _dbSet.AnyAsync(x => 
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
            return user;
        }


        public async Task<bool> CheckUsernameExists(string username)
        {
            return await _dbSet.AnyAsync(x => x.Username == username);
        }

        public async Task<bool> CheckEmailExists(string email)
        {
            return await _dbSet.AnyAsync(x => x.Email == email);
        }

        public async Task<IEnumerable<User>> GetActiveUsers()
        {
            return await _dbSet.Where(x => x.IsActive).ToListAsync();
        }

        public async Task<IEnumerable<User>> GetInactiveUsers()
        {
            return await _dbSet.Where(x => !x.IsActive).ToListAsync();
        }

        protected override User MapToEntity(UserInsertRequest insert)
        {
            if (insert.Username != null && CheckUsernameExists(insert.Username).Result)
                throw new ConflictException(ErrorMessages.UsernameExists);

            if (insert.Email != null && CheckEmailExists(insert.Email).Result)
                throw new ConflictException(ErrorMessages.EmailExists);

            var now = DateTime.UtcNow;
            return new User
            {
                FirstName = insert.FirstName ?? string.Empty,
                LastName = insert.LastName ?? string.Empty,
                Username = insert.Username ?? string.Empty,
                Email = insert.Email ?? string.Empty,
                PhoneNumber = insert.PhoneNumber ?? string.Empty,
                PasswordHash = !string.IsNullOrEmpty(insert.Password) ? BCrypt.Net.BCrypt.HashPassword(insert.Password) : null,
                RoleId = insert.RoleId > 0 ? insert.RoleId : 2, // Default to User role (ID 2)
                Picture = insert.Picture,
                PasswordUpdateDate = !string.IsNullOrEmpty(insert.Password) ? now : null,
                DeactivationDate = null
            };
        }

        protected override void MapToEntity(UserUpdateRequest update, User entity)
        {
            if (update.Username != null && CheckUsernameExists(update.Username).Result && entity.Username != update.Username)
                throw new ConflictException(ErrorMessages.UsernameExists);

            if (update.Email != null && CheckEmailExists(update.Email).Result && entity.Email != update.Email)
                throw new ConflictException(ErrorMessages.EmailExists);

            if (update.FirstName != null) entity.FirstName = update.FirstName;
            if (update.LastName != null) entity.LastName = update.LastName;
            if (update.Username != null) entity.Username = update.Username;
            if (update.Email != null) entity.Email = update.Email;
            if (update.PhoneNumber != null) entity.PhoneNumber = update.PhoneNumber;
            // Don't change RoleId if not specified (0 is not a valid role ID)
            if (update.RoleId > 0) entity.RoleId = update.RoleId;

            if (update.Picture != null)
            {
                entity.Picture = update.Picture;
            }

            if (!string.IsNullOrEmpty(update.Password))
            {
                entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(update.Password);
                entity.PasswordUpdateDate = DateTime.UtcNow;
            }
            entity.UpdateDate = DateTime.UtcNow;
        }

        public override async Task<User> Patch(int id, UserPatchRequest patch)
        {
            var entity = await GetById(id);
            
            // Validate username uniqueness if it's being changed
            if (patch.Username != null && entity.Username != patch.Username)
            {
                var usernameExists = await CheckUsernameExists(patch.Username);
                if (usernameExists)
                    throw new ConflictException(ErrorMessages.UsernameExists);
            }
            
            // Validate email uniqueness if it's being changed
            if (patch.Email != null && entity.Email != patch.Email)
            {
                var emailExists = await CheckEmailExists(patch.Email);
                if (emailExists)
                    throw new ConflictException(ErrorMessages.EmailExists);
            }
            
            MapToEntity(patch, entity);
            await _context.SaveChangesAsync();
            return entity;
        }



        protected override void MapToEntity(UserPatchRequest patch, User entity)
        {
            // Convert empty strings to null
            if (string.IsNullOrWhiteSpace(patch.Email)) patch.Email = null;
            if (string.IsNullOrWhiteSpace(patch.FirstName)) patch.FirstName = null;
            if (string.IsNullOrWhiteSpace(patch.LastName)) patch.LastName = null;
            if (string.IsNullOrWhiteSpace(patch.PhoneNumber)) patch.PhoneNumber = null;
            if (string.IsNullOrWhiteSpace(patch.Username)) patch.Username = null;

            // Only update fields that are provided (not null)
            if (patch.FirstName != null)
            {
                entity.FirstName = patch.FirstName;
            }

            if (patch.LastName != null)
            {
                entity.LastName = patch.LastName;
            }

            if (patch.Username != null)
            {
                // Note: This will be handled properly in the async version
                entity.Username = patch.Username;
            }

            if (patch.Email != null)
            {
                // Validate email format
                try
                {
                    var addr = new System.Net.Mail.MailAddress(patch.Email);
                    if (addr.Address != patch.Email)
                        throw new ValidationException(ErrorMessages.InvalidEmail);
                }
                catch
                {
                    throw new ValidationException(ErrorMessages.InvalidEmail);
                }

                entity.Email = patch.Email;
            }

            if (patch.PhoneNumber != null)
            {
                entity.PhoneNumber = patch.PhoneNumber;
            }

            if (patch.Picture != null)
            {
                entity.Picture = patch.Picture;
            }

            entity.UpdateDate = DateTime.UtcNow;
        }

        public async Task<UserResponse> GetUserDetailsAsResponse(int id)
        {
            var user = await GetById(id);
            return MapToResponse(user);
        }

        public async Task<UserResponse> GetMeAsResponse(int userId)
        {
            var user = await GetById(userId);
            return MapToResponse(user);
        }

        public async Task<UserResponse> UpdateProfileAsResponse(int userId, UserProfileUpdateRequest request)
        {
            var user = await UpdateProfile(userId, request);
            return MapToResponse(user);
        }

        public async Task<UserResponse> UploadPictureAsResponse(int userId, byte[] picture)
        {
            var user = await GetById(userId);
            user.Picture = picture;
            
            await Update(user.Id, new UserUpdateRequest
            {
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Username = user.Username,
                RoleId = user.RoleId,
                Picture = picture
            });

            // Reload with includes
            var updatedUser = await GetById(userId);
            return MapToResponse(updatedUser);
        }

        public async Task<bool> DeletePictureAsResponse(int userId)
        {
            var user = await GetById(userId);
            user.Picture = null;
            
            await Update(user.Id, new UserUpdateRequest
            {
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Username = user.Username,
                RoleId = user.RoleId,
                Picture = null
            });

            return true;
        }

        public async Task<UserResponse> RegisterAsResponse(UserRegisterRequest request)
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

            var user = await Insert(insertRequest);
            return MapToResponse(user);
        }

        private UserResponse MapToResponse(User entity)
        {
            return new UserResponse
            {
                Id = entity.Id,
                FirstName = entity.FirstName,
                LastName = entity.LastName,
                Email = entity.Email,
                PhoneNumber = entity.PhoneNumber,
                Username = entity.Username,
                Picture = entity.Picture != null ? Convert.ToBase64String(entity.Picture) : null,
                RoleId = entity.RoleId,
                RoleName = entity.Role?.Name,
                IsActive = entity.IsActive,
                CreatedAt = entity.CreatedAt,
                LastLogin = entity.LastLogin
            };
        }
    }
}
