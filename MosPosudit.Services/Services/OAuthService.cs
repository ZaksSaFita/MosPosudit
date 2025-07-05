using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Facebook;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Authentication.MicrosoftAccount;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using MosPosudit.Model.Exceptions;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;
using System.Security.Claims;

namespace MosPosudit.Services.Services
{
    public class OAuthService : IOAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public OAuthService(ApplicationDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public AuthenticationProperties ConfigureGoogleAuth()
        {
            return new AuthenticationProperties
            {
                RedirectUri = "/api/auth/google-callback",
                Items =
                {
                    { "scheme", GoogleDefaults.AuthenticationScheme }
                }
            };
        }

        public AuthenticationProperties ConfigureMicrosoftAuth()
        {
            return new AuthenticationProperties
            {
                RedirectUri = "/api/auth/microsoft-callback",
                Items =
                {
                    { "scheme", MicrosoftAccountDefaults.AuthenticationScheme }
                }
            };
        }

        public AuthenticationProperties ConfigureFacebookAuth()
        {
            return new AuthenticationProperties
            {
                RedirectUri = "/api/auth/facebook-callback",
                Items =
                {
                    { "scheme", FacebookDefaults.AuthenticationScheme }
                }
            };
        }

        public async Task<ClaimsPrincipal> HandleGoogleCallback(ClaimsPrincipal principal)
        {
            var email = principal.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
                throw new ValidationException("Email not found in Google claims");

            var user = await _context.Users
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Email == email);
            if (user == null)
            {
                // Create new user from Google data
                user = new User
                {
                    Email = email,
                    FirstName = principal.FindFirst(ClaimTypes.GivenName)?.Value,
                    LastName = principal.FindFirst(ClaimTypes.Surname)?.Value,
                    Username = email,
                    RoleId = 2, // Default role for external users
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Name, $"{user.FirstName} {user.LastName}"),
                new Claim(ClaimTypes.Role, user.Role.Name)
            };

            return new ClaimsPrincipal(new ClaimsIdentity(claims, "OAuth"));
        }

        public async Task<ClaimsPrincipal> HandleMicrosoftCallback(ClaimsPrincipal principal)
        {
            var email = principal.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
                throw new ValidationException("Email not found in Microsoft claims");

            var user = await _context.Users
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Email == email);
            if (user == null)
            {
                user = new User
                {
                    Email = email,
                    FirstName = principal.FindFirst(ClaimTypes.GivenName)?.Value,
                    LastName = principal.FindFirst(ClaimTypes.Surname)?.Value,
                    Username = email,
                    RoleId = 2,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Name, $"{user.FirstName} {user.LastName}"),
                new Claim(ClaimTypes.Role, user.Role.Name)
            };

            return new ClaimsPrincipal(new ClaimsIdentity(claims, "OAuth"));
        }

        public async Task<ClaimsPrincipal> HandleFacebookCallback(ClaimsPrincipal principal)
        {
            var email = principal.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
                throw new ValidationException("Email not found in Facebook claims");

            var user = await _context.Users
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Email == email);
            if (user == null)
            {
                user = new User
                {
                    Email = email,
                    FirstName = principal.FindFirst(ClaimTypes.GivenName)?.Value,
                    LastName = principal.FindFirst(ClaimTypes.Surname)?.Value,
                    Username = email,
                    RoleId = 2,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Name, $"{user.FirstName} {user.LastName}"),
                new Claim(ClaimTypes.Role, user.Role.Name)
            };

            return new ClaimsPrincipal(new ClaimsIdentity(claims, "OAuth"));
        }
    }
}
