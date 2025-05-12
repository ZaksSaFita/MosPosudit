using Microsoft.EntityFrameworkCore;
using MošPosudit.Model.Exceptions;
using MošPosudit.Model.Messages;
using MošPosudit.Model.Requests.User;
using MošPosudit.Model.SearchObjects;
using MošPosudit.Services.DataBase;
using MošPosudit.Services.DataBase.Data;
using MošPosudit.Services.Interfaces;

namespace MošPosudit.Services.Services
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

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Username))
                    query = query.Where(x => x.Username.Contains(search.Username));

                if (!string.IsNullOrWhiteSpace(search.Email))
                    query = query.Where(x => x.Email.Contains(search.Email));
            }

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                            .Take(search.PageSize.Value);
            }

            return await query.ToListAsync();
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

        public async Task<bool> ChangePassword(int id, string newPassword)
        {
            var user = await GetById(id);
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.PasswordUpdateDate = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
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
            if (CheckUsernameExists(insert.Username).Result)
                throw new ConflictException(ErrorMessages.UsernameExists);

            if (CheckEmailExists(insert.Email).Result)
                throw new ConflictException(ErrorMessages.EmailExists);

            var now = DateTime.UtcNow;
            return new User
            {
                FirstName = insert.FirstName,
                LastName = insert.LastName,
                Username = insert.Username,
                Email = insert.Email,
                PhoneNumber = insert.PhoneNumber,
                Address = insert.Address,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(insert.Password),
                RoleId = insert.RoleId,
                IsActive = true,
                CreatedAt = now,
                UpdateDate = now,
                PasswordUpdateDate = now,
                DeactivationDate = null
            };
        }

        protected override void MapToEntity(UserUpdateRequest update, User entity)
        {
            if (CheckUsernameExists(update.Username).Result && entity.Username != update.Username)
                throw new ConflictException(ErrorMessages.UsernameExists);

            if (CheckEmailExists(update.Email).Result && entity.Email != update.Email)
                throw new ConflictException(ErrorMessages.EmailExists);

            entity.FirstName = update.FirstName;
            entity.LastName = update.LastName;
            entity.Username = update.Username;
            entity.Email = update.Email;
            entity.PhoneNumber = update.PhoneNumber;
            entity.Address = update.Address;
            entity.RoleId = update.RoleId;

            if (!string.IsNullOrEmpty(update.Password))
            {
                entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(update.Password);
            }
            entity.UpdateDate = DateTime.UtcNow;
        }

        public override async Task<User> Patch(int id, UserPatchRequest patch)
        {
            var entity = await GetById(id);
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
            if (string.IsNullOrWhiteSpace(patch.Address)) patch.Address = null;
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
                if (CheckUsernameExists(patch.Username).Result && entity.Username != patch.Username)
                    throw new ConflictException(ErrorMessages.UsernameExists);
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

                if (CheckEmailExists(patch.Email).Result && entity.Email != patch.Email)
                    throw new ConflictException(ErrorMessages.EmailExists);
                entity.Email = patch.Email;
            }

            if (patch.PhoneNumber != null)
            {
                entity.PhoneNumber = patch.PhoneNumber;
            }

            if (patch.Address != null)
            {
                entity.Address = patch.Address;
            }

            entity.UpdateDate = DateTime.UtcNow;
        }
    }
}