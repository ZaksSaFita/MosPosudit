using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.Interfaces;
using System.Linq;

namespace MosPosudit.Services.DataBase.Extensions
{
    public static class DatabaseInitializer
    {
        /// <summary>
        /// Waits for SQL Server to be ready, applies migrations, and seeds the database
        /// </summary>
        public static async Task InitializeDatabaseAsync(
            IServiceProvider serviceProvider,
            IConfiguration configuration,
            ILogger logger,
            string contentRootPath)
        {
            try
            {
                using var scope = serviceProvider.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var connectionString = configuration.GetConnectionString("DefaultConnection");
                // Replace any database name with master for connection test
                var masterConnectionString = connectionString;
                if (!string.IsNullOrEmpty(connectionString))
                {
                    // Extract database name and replace with master
                    var dbNameMatch = System.Text.RegularExpressions.Regex.Match(connectionString, @"Database=([^;]+);");
                    if (dbNameMatch.Success)
                    {
                        masterConnectionString = connectionString.Replace($"Database={dbNameMatch.Groups[1].Value};", "Database=master;");
                    }
                }

                // Wait for SQL Server to be ready
                await WaitForSqlServerAsync(masterConnectionString, logger);

                // Apply migrations
                await ApplyMigrationsAsync(db, logger);

                // Seed database
                var seeder = scope.ServiceProvider.GetRequiredService<ISeedService>();
                seeder.SeedIfEmpty(db, contentRootPath);

                logger.LogInformation("Database initialization completed successfully");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "An error occurred while initializing the database");
                throw;
            }
        }

        private static async Task WaitForSqlServerAsync(string? masterConnectionString, ILogger logger)
        {
            var maxRetries = 30;
            var retryCount = 0;

            while (retryCount < maxRetries)
            {
                try
                {
                    var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
                    optionsBuilder.UseSqlServer(masterConnectionString);
                    using var testContext = new ApplicationDbContext(optionsBuilder.Options);

                    if (testContext.Database.CanConnect())
                    {
                        logger.LogInformation("SQL Server is ready");
                        return;
                    }
                }
                catch (Exception ex)
                {
                    retryCount++;
                    if (retryCount >= maxRetries)
                    {
                        logger.LogError(ex, "Failed to connect to SQL Server after {MaxRetries} attempts", maxRetries);
                        throw;
                    }

                    logger.LogWarning("SQL Server not ready yet, waiting 2 seconds before retry... (attempt {Attempt}/{MaxRetries})", retryCount, maxRetries);
                    await Task.Delay(2000);
                }
            }
        }

        private static async Task ApplyMigrationsAsync(ApplicationDbContext db, ILogger logger)
        {
            try
            {
                var pendingMigrations = db.Database.GetPendingMigrations().ToList();
                
                if (pendingMigrations.Any())
                {
                    logger.LogInformation("Applying {Count} pending migration(s)...", pendingMigrations.Count);
                    await Task.Run(() => db.Database.Migrate());
                    logger.LogInformation("Migrations applied successfully");
                }
                else
                {
                    logger.LogInformation("Database is up to date, no pending migrations");
                }
            }
            catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 2714) // Object already exists
            {
                logger.LogWarning("Some database objects already exist. This might indicate a previous incomplete migration.");
                logger.LogWarning("Attempting to synchronize migration history...");

                await SynchronizeMigrationHistoryAsync(db, logger);
            }
        }

        private static async Task SynchronizeMigrationHistoryAsync(ApplicationDbContext db, ILogger logger)
        {
            try
            {
                var appliedMigrations = db.Database.GetAppliedMigrations().ToList();
                var allMigrations = db.Database.GetMigrations().ToList();
                var pendingMigrations = allMigrations.Except(appliedMigrations).ToList();

                if (pendingMigrations.Any())
                {
                    // Try to mark pending migrations as applied if tables already exist
                    foreach (var migration in pendingMigrations)
                    {
                        try
                        {
                            await db.Database.ExecuteSqlRawAsync(
                                $"IF NOT EXISTS (SELECT * FROM [__EFMigrationsHistory] WHERE [MigrationId] = '{migration}') " +
                                $"INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion]) VALUES ('{migration}', '8.0.0')");
                            logger.LogInformation("Marked migration {Migration} as applied", migration);
                        }
                        catch (Exception e)
                        {
                            logger.LogWarning(e, "Could not mark migration {Migration} as applied", migration);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                logger.LogError(e, "Error synchronizing migration history");
                // Continue anyway - might work if tables are already there
            }
        }
    }
}

