using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace MošPosudit.Services.DataBase.Extensions
{
    public static class DatabaseConfiguration
    {
        // Configures the database context and adds it to the service collection
        public static void AddDatabaseServices(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(connectionString));
        }

        // Configures decimal precision and scale for all decimal properties in the model
        // Sets precision to 18 and scale to 2 for all decimal properties
        public static void ConfigureDecimalPrecision(this ModelBuilder modelBuilder)
        {
            foreach (var property in modelBuilder.Model.GetEntityTypes()
                .SelectMany(t => t.GetProperties())
                .Where(p => p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?)))
            {
                property.SetPrecision(18);
                property.SetScale(2);
            }
        }
    }
} 