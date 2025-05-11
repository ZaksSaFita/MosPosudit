using Microsoft.EntityFrameworkCore;
using MošPosudit.Model.DTOs;
using MošPosudit.Model.Exceptions;
using MošPosudit.Model.Messages;
using MošPosudit.Model.Responses;
using MošPosudit.Model.SearchObjects;
using MošPosudit.Services.DataBase;
using MošPosudit.Services.DataBase.Data;
using MošPosudit.Services.Interfaces;
using System.Security.Cryptography;
using System.Text;

namespace MošPosudit.Services.Services
{
    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _context;
        private readonly JwtService _jwtService;

        public UserService(ApplicationDbContext context, JwtService jwtService)
        {
            _context = context;
            _jwtService = jwtService;
        }

        public async Task<UserResponse> GetById(int id)
        {
            var user = await _context.Users
                .Include(x => x.Role)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (user == null)
                throw new BusinessException(ErrorMessages.UserNotFound);

            return MapToResponse(user);
        }

        public async Task<PagedResult<UserResponse>> Get(UserSearchObject search)
        {
            var query = _context.Users
                .Include(x => x.Role)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search?.Username))
                query = query.Where(x => x.Username.Contains(search.Username));

            if (!string.IsNullOrWhiteSpace(search?.Email))
                query = query.Where(x => x.Email.Contains(search.Email));

            if (search?.RoleId.HasValue == true)
                query = query.Where(x => x.RoleId == search.RoleId);

            if (search?.IsActive.HasValue == true)
                query = query.Where(x => x.IsActive == search.IsActive);

            var total = await query.CountAsync();

            var items = await query
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .ToListAsync();

            return new PagedResult<UserResponse>
            {
                Total = total,
                Items = items.Select(MapToResponse).ToList()
            };
        }

        public async Task<UserResponse> Insert(UserInsertRequest request)
        {
            if (await _context.Users.AnyAsync(x => x.Username == request.Username))
                throw new BusinessException(ErrorMessages.UsernameExists);

            if (await _context.Users.AnyAsync(x => x.Email == request.Email))
                throw new BusinessException(ErrorMessages.EmailExists);

            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                Address = request.Address,
                Username = request.Username,
                Password = HashPassword(request.Password),
                RoleId = request.RoleId,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        public async Task<UserResponse> Update(int id, UserUpdateRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new BusinessException(ErrorMessages.UserNotFound);

            if (request.Email != user.Email && await _context.Users.AnyAsync(x => x.Email == request.Email))
                throw new BusinessException(ErrorMessages.EmailExists);

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.Email = request.Email;
            user.PhoneNumber = request.PhoneNumber;
            user.Address = request.Address;
            user.RoleId = request.RoleId;

            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        public async Task<UserResponse> Delete(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new BusinessException(ErrorMessages.UserNotFound);

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        public async Task<UserResponse> Login(string username, string password)
        {
            var user = await _context.Users
                .Include(x => x.Role)
                .FirstOrDefaultAsync(x => x.Username == username);

            if (user == null || !VerifyPassword(password, user.Password))
                throw new BusinessException(ErrorMessages.InvalidCredentials);

            if (!user.IsActive)
                throw new BusinessException(ErrorMessages.UserDeactivated);

            user.LastLogin = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            var response = MapToResponse(user);
            response.Token = _jwtService.GenerateToken(response);
            return response;
        }

        public async Task<UserResponse> Register(UserInsertRequest request)
        {
            // Set default role for new registrations (e.g., Customer role)
            request.RoleId = 2; // Assuming 2 is the ID for Customer role
            var response = await Insert(request);
            response.Token = _jwtService.GenerateToken(response);
            return response;
        }

        public async Task<UserResponse> ChangePassword(int id, string oldPassword, string newPassword)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new BusinessException(ErrorMessages.UserNotFound);

            if (!VerifyPassword(oldPassword, user.Password))
                throw new BusinessException(ErrorMessages.InvalidPassword);

            user.Password = HashPassword(newPassword);
            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        public async Task<UserResponse> Deactivate(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new BusinessException(ErrorMessages.UserNotFound);

            user.IsActive = false;
            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        public async Task<UserResponse> Activate(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new BusinessException(ErrorMessages.UserNotFound);

            user.IsActive = true;
            await _context.SaveChangesAsync();

            return MapToResponse(user);
        }

        private string HashPassword(string password)
        {
            using (var sha256 = SHA256.Create())
            {
                var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(hashedBytes);
            }
        }

        private bool VerifyPassword(string password, string hashedPassword)
        {
            return HashPassword(password) == hashedPassword;
        }

        private UserResponse MapToResponse(User user)
        {
            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Address = user.Address,
                Username = user.Username,
                RoleId = user.RoleId,
                RoleName = user.Role?.Name,
                CreatedAt = user.CreatedAt,
                LastLogin = user.LastLogin,
                IsActive = user.IsActive
            };
        }
    }
} 