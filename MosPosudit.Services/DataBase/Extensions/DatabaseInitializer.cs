using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.Interfaces;
using System.Linq;
using System.Text.RegularExpressions;

namespace MosPosudit.Services.DataBase.Extensions
{
    public static class DatabaseInitializer
    {
        private const int MaxRetries = 30;
        private const int RetryDelayMs = 2000;

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
                var connectionString = configuration.GetConnectionString("DefaultConnection") 
                    ?? throw new InvalidOperationException("Connection string not found");

                var (dbName, masterConnectionString) = ExtractDatabaseInfo(connectionString);

                // Step 1: Wait for SQL Server
                await WaitForSqlServerAsync(masterConnectionString, logger);

                // Step 2: Ensure database exists
                await EnsureDatabaseExistsAsync(dbName, masterConnectionString, logger);

                // Step 3: Wait for database connection
                await WaitForConnectionAsync(db, logger);

                // Step 4: Apply migrations (creates all tables in correct order)
                await ApplyMigrationsAsync(db, logger);

                // Step 5: Seed data in correct order
                var seeder = scope.ServiceProvider.GetRequiredService<ISeedService>();
                seeder.SeedIfEmpty(db, contentRootPath);
                seeder.SeedRecommendationSettingsIfNeeded(db);

                logger.LogInformation("Database initialization completed successfully");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "An error occurred while initializing the database");
                throw;
            }
        }

        private static (string dbName, string masterConnectionString) ExtractDatabaseInfo(string connectionString)
        {
            var match = Regex.Match(connectionString, @"Database=([^;]+);?");
            if (!match.Success)
                throw new InvalidOperationException("Could not extract database name from connection string");

            var dbName = match.Groups[1].Value;
            var masterConnectionString = connectionString.Replace($"Database={dbName};", "Database=master;");
            return (dbName, masterConnectionString);
        }

        private static async Task WaitForSqlServerAsync(string masterConnectionString, ILogger logger)
        {
            for (int attempt = 1; attempt <= MaxRetries; attempt++)
            {
                try
                {
                    using var context = CreateContext(masterConnectionString);
                    if (context.Database.CanConnect())
                    {
                        logger.LogInformation("SQL Server is ready");
                        return;
                    }
                }
                catch (Exception ex)
                {
                    if (attempt >= MaxRetries)
                    {
                        logger.LogError(ex, "Failed to connect to SQL Server after {MaxRetries} attempts", MaxRetries);
                        throw;
                    }
                    logger.LogWarning("SQL Server not ready, waiting... (attempt {Attempt}/{MaxRetries})", attempt, MaxRetries);
                    await Task.Delay(RetryDelayMs);
                }
            }
        }

        private static async Task WaitForConnectionAsync(ApplicationDbContext db, ILogger logger)
        {
            for (int attempt = 1; attempt <= MaxRetries; attempt++)
            {
                try
                {
                    if (await db.Database.CanConnectAsync())
                    {
                        logger.LogInformation("Database connection established");
                        return;
                    }
                }
                catch (Exception ex)
                {
                    if (attempt >= MaxRetries)
                    {
                        logger.LogError(ex, "Failed to establish database connection after {MaxRetries} attempts", MaxRetries);
                        throw;
                    }
                    logger.LogWarning("Database not ready, waiting... (attempt {Attempt}/{MaxRetries})", attempt, MaxRetries);
                    await Task.Delay(RetryDelayMs);
                }
            }
        }

        private static async Task EnsureDatabaseExistsAsync(string dbName, string masterConnectionString, ILogger logger)
        {
            try
            {
                using var masterContext = CreateContext(masterConnectionString);
                await using var connection = masterContext.Database.GetDbConnection();
                await connection.OpenAsync();

                var checkCmd = connection.CreateCommand();
                checkCmd.CommandText = $"SELECT COUNT(*) FROM sys.databases WHERE name = '{dbName}'";
                var exists = Convert.ToInt32(await checkCmd.ExecuteScalarAsync()) > 0;

                if (exists)
                {
                    logger.LogInformation("Database '{DatabaseName}' already exists", dbName);
                    return;
                }

                logger.LogInformation("Creating database '{DatabaseName}'...", dbName);
                var createCmd = connection.CreateCommand();
                createCmd.CommandText = $"CREATE DATABASE [{dbName}]";
                await createCmd.ExecuteNonQueryAsync();
                logger.LogInformation("Database '{DatabaseName}' created successfully", dbName);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error ensuring database exists. Continuing with migration attempt...");
            }
        }

        private static async Task ApplyMigrationsAsync(ApplicationDbContext db, ILogger logger)
        {
            for (int attempt = 1; attempt <= MaxRetries; attempt++)
            {
                try
                {
                    var pendingMigrations = db.Database.GetPendingMigrations().ToList();
                    
                    if (!pendingMigrations.Any())
                    {
                        logger.LogInformation("Database is up to date, no pending migrations");
                        return;
                    }

                    logger.LogInformation("Applying {Count} pending migration(s): {Migrations}", 
                        pendingMigrations.Count, string.Join(", ", pendingMigrations));
                    
                    await db.Database.MigrateAsync();
                    logger.LogInformation("Migrations applied successfully");
                    return;
                }
                catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 2714)
                {
                    logger.LogWarning("Migration conflict detected. Synchronizing migration history...");
                    await SynchronizeMigrationHistoryAsync(db, logger);
                    return;
                }
                catch (Exception ex)
                {
                    if (attempt >= MaxRetries)
                    {
                        logger.LogError(ex, "Failed to apply migrations after {MaxRetries} attempts", MaxRetries);
                        throw;
                    }
                    logger.LogWarning(ex, "Error applying migrations (attempt {Attempt}/{MaxRetries}). Retrying...", attempt, MaxRetries);
                    await Task.Delay(RetryDelayMs);
                }
            }
        }

        private static async Task SynchronizeMigrationHistoryAsync(ApplicationDbContext db, ILogger logger)
        {
            try
            {
                var pending = db.Database.GetMigrations().Except(db.Database.GetAppliedMigrations()).ToList();
                
                foreach (var migration in pending)
                {
                    try
                    {
                        await db.Database.ExecuteSqlRawAsync(
                            $"IF NOT EXISTS (SELECT * FROM [__EFMigrationsHistory] WHERE [MigrationId] = '{migration}') " +
                            $"INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion]) VALUES ('{migration}', '8.0.4')");
                        logger.LogInformation("Marked migration {Migration} as applied", migration);
                    }
                    catch (Exception e)
                    {
                        logger.LogWarning(e, "Could not mark migration {Migration} as applied", migration);
                    }
                }
            }
            catch (Exception e)
            {
                logger.LogError(e, "Error synchronizing migration history");
            }
        }

        private static ApplicationDbContext CreateContext(string connectionString)
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseSqlServer(connectionString)
                .Options;
            return new ApplicationDbContext(options);
        }
    }
}
