using Microsoft.EntityFrameworkCore;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Extensions;
using MosPosudit.Services.Interfaces;
using MosPosudit.Services.Services;

namespace MosPosudit.WebAPI.Extensions
{
    public static class ServiceCollectionExtensions
    {
        public static IServiceCollection AddApplicationServices(this IServiceCollection services, IConfiguration configuration)
        {
            // Configure DbContext
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(configuration.GetConnectionString("DefaultConnection"),
                    sqlServerOptionsAction: sqlOptions =>
                    {
                        sqlOptions.EnableRetryOnFailure(
                            maxRetryCount: 5,
                            maxRetryDelay: TimeSpan.FromSeconds(30),
                            errorNumbersToAdd: null);
                    }));

            // Register application services
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<IAuthService, AuthService>();
            services.AddSingleton<IMessageService, MessageService>();
            services.AddScoped<ISeedService, SeedService>();
            services.AddScoped<IToolService, ToolService>();
            services.AddScoped<ICategoryService, CategoryService>();
            services.AddScoped<IChatService, ChatService>();
            services.AddScoped<IReviewService, ReviewService>();
            services.AddScoped<IUserFavoriteService, UserFavoriteService>();
            services.AddScoped<INotificationService, NotificationService>();
            services.AddScoped<IOrderService, OrderService>();
            services.AddScoped<IPaymentService, PaymentService>();

            services.AddHttpClient();

            return services;
        }

        public static IServiceCollection AddApplicationControllers(this IServiceCollection services)
        {
            // Add CORS
            services.AddCors(options =>
            {
                options.AddDefaultPolicy(policy =>
                {
                    policy
                        .AllowAnyOrigin()
                        .AllowAnyMethod()
                        .AllowAnyHeader();
                });
            });

            services.AddControllers()
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
                    options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
                    options.JsonSerializerOptions.WriteIndented = true;
                });

            return services;
        }
    }
}

