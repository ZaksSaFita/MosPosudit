using MosPosudit.Services.DataBase.Extensions;

namespace MosPosudit.WebAPI.Extensions
{
    public static class WebApplicationExtensions
    {
        public static WebApplication UseApplicationMiddleware(this WebApplication app)
        {
            // Configure the HTTP request pipeline
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            // Add CORS
            app.UseCors(x => x
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader());

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            return app;
        }

        public static async Task InitializeDatabaseAsync(this WebApplication app, IConfiguration configuration, string contentRootPath)
        {
            var logger = app.Services.GetRequiredService<ILogger<Program>>();
            await DatabaseInitializer.InitializeDatabaseAsync(
                app.Services,
                configuration,
                logger,
                contentRootPath);
        }
    }
}

