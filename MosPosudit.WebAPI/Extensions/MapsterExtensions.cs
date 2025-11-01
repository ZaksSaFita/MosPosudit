using Mapster;
using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;

namespace MosPosudit.WebAPI.Extensions
{
    public static class MapsterExtensions
    {
        public static IServiceCollection AddMapsterConfiguration(this IServiceCollection services)
        {
            var config = TypeAdapterConfig.GlobalSettings;
            services.AddSingleton(config);
            services.AddScoped<IMapper, ServiceMapper>();

            return services;
        }
    }
}

