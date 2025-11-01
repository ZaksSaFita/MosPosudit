using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;

namespace MosPosudit.WebAPI.Extensions
{
    public static class JwtExtensions
    {
        public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                var jwtKey = configuration["Jwt:Key"]
                    ?? throw new InvalidOperationException("JWT Key is not configured. Please set Jwt:Key in configuration.");

                if (jwtKey.Length < 32)
                    throw new InvalidOperationException("JWT Key must be at least 32 characters long.");

                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = configuration["Jwt:Issuer"] ?? "MosPosudit",
                    ValidAudience = configuration["Jwt:Audience"] ?? "MosPosuditUsers",
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                    RoleClaimType = ClaimTypes.Role
                };
            });

            return services;
        }
    }
}

