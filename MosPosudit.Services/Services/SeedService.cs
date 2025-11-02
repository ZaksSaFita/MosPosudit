using System.Text.Json;
using System.IO;
using System.Linq;
using MosPosudit.Services.DataBase;
using MosPosudit.Services.DataBase.Data;
using MosPosudit.Services.Interfaces;

namespace MosPosudit.Services.Services
{
    public class SeedService : ISeedService
    {
        private class SeedCategoryDto { public int id { get; set; } public string name { get; set; } = string.Empty; public string? description { get; set; } }
        private class SeedToolDto { public int id { get; set; } public string name { get; set; } = string.Empty; public int categoryId { get; set; } public string? description { get; set; } public decimal dailyPrice { get; set; } public bool available { get; set; } public string? image { get; set; } }
        private class SeedPayload { public List<SeedCategoryDto> categories { get; set; } = new(); public List<SeedToolDto> tools { get; set; } = new(); }

        public void SeedIfEmpty(ApplicationDbContext db, string contentRootPath)
        {
            var didChange = false;

            if (!db.Roles.Any())
            {
                db.Roles.AddRange(new Role { Name = "Admin", Description = "Administrator role" }, new Role { Name = "User", Description = "Regular user role" });
                db.SaveChanges(); // MORAMO sačuvati role PRE nego što ih koristimo za korisnike
                didChange = true;
            }

            // Seed default users (admin and user) - update if exists, create if not
            var adminRole = db.Roles.FirstOrDefault(x => x.Name == "Admin");
            var userRole = db.Roles.FirstOrDefault(x => x.Name == "User");
            
            if (adminRole == null || userRole == null)
                throw new InvalidOperationException("Roles must be seeded before users can be created.");
            
            var now = DateTime.UtcNow;
            var adminRoleId = adminRole.Id;
            var userRoleId = userRole.Id;

            // Ensure admin user exists with correct email
            var adminUser = db.Users.FirstOrDefault(x => x.Username == "admin");
            if (adminUser == null)
            {
                db.Users.Add(new User
                {
                    FirstName = "Admin",
                    LastName = "User",
                    Username = "admin",
                    Email = "mosposudit2@gmail.com",
                    PhoneNumber = "123456789",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                    RoleId = adminRoleId,
                    IsActive = true,
                    CreatedAt = now,
                    UpdateDate = now,
                    PasswordUpdateDate = now
                });
                didChange = true;
            }
            else if (adminUser.Email != "mosposudit2@gmail.com")
            {
                // Update email if different
                adminUser.Email = "mosposudit2@gmail.com";
                adminUser.UpdateDate = now;
                didChange = true;
            }

            // Ensure regular user exists with correct email
            var regularUser = db.Users.FirstOrDefault(x => x.Username == "user");
            if (regularUser == null)
            {
                db.Users.Add(new User
                {
                    FirstName = "Regular",
                    LastName = "User",
                    Username = "user",
                    Email = "mosposudit3@gmail.com",
                    PhoneNumber = "987654321",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                    RoleId = userRoleId,
                    IsActive = true,
                    CreatedAt = now,
                    UpdateDate = now,
                    PasswordUpdateDate = now
                });
                didChange = true;
            }
            else if (regularUser.Email != "mosposudit3@gmail.com")
            {
                // Update email if different
                regularUser.Email = "mosposudit3@gmail.com";
                regularUser.UpdateDate = now;
                didChange = true;
            }

            if (didChange) db.SaveChanges();


            // Load categories/tools from JSON if present; otherwise use built-in defaults
            SeedPayload? payload = null;
            try
            {
                var seedPath = Path.Combine(contentRootPath, "Seed", "seed.json");
                if (File.Exists(seedPath))
                {
                    var json = File.ReadAllText(seedPath);
                    payload = JsonSerializer.Deserialize<SeedPayload>(json);
                }
            }
            catch { /* ignore and fallback */ }

            payload ??= new SeedPayload
            {
                categories = new List<SeedCategoryDto>
                {
                    new SeedCategoryDto{ id=1, name="Power Tools"},
                    new SeedCategoryDto{ id=2, name="Hand Tools"},
                    new SeedCategoryDto{ id=3, name="Garden Tools"},
                    new SeedCategoryDto{ id=4, name="Measuring Tools"},
                    new SeedCategoryDto{ id=5, name="Construction Tools"},
                    new SeedCategoryDto{ id=6, name="Specialized Equipment"},
                },
                tools = new List<SeedToolDto>
                {
                    new SeedToolDto{ id=1, name="Makita DHP453 Cordless Drill", categoryId=1, description="Professional cordless drill with two speeds and strong torque.", dailyPrice=7.5m, available=true },
                    new SeedToolDto{ id=2, name="Bosch GWS 750 Angle Grinder", categoryId=1, description="High-power angle grinder, 750W for metal and concrete cutting.", dailyPrice=8m, available=true },
                    new SeedToolDto{ id=3, name="500g Hammer", categoryId=2, description="Standard hammer suitable for basic household work.", dailyPrice=2m, available=true },
                    new SeedToolDto{ id=4, name="8-24mm Wrench Set", categoryId=2, description="Professional wrench set for mechanic and assembly work.", dailyPrice=3.5m, available=true },
                    new SeedToolDto{ id=5, name="Husqvarna 120 Chainsaw", categoryId=3, description="Gas-powered chainsaw, 38cc engine, ideal for wood cutting.", dailyPrice=12m, available=true },
                    new SeedToolDto{ id=6, name="Einhell Electric Lawn Mower", categoryId=3, description="Electric lawn mower, 1400W, great for medium yards.", dailyPrice=10m, available=true },
                    new SeedToolDto{ id=7, name="Bosch Digital Laser Level 60cm", categoryId=4, description="Digital level with laser guide, highly accurate.", dailyPrice=5m, available=true },
                    new SeedToolDto{ id=8, name="Hydraulic Car Jack 2T", categoryId=5, description="Strong hydraulic jack suitable for cars up to 2 tons.", dailyPrice=6.5m, available=true },
                    new SeedToolDto{ id=9, name="Karcher WD5 Industrial Vacuum", categoryId=6, description="Industrial-grade vacuum for dust and water, 1100W.", dailyPrice=9m, available=true },
                }
            };

            // Seed Categories
            foreach (var c in payload.categories)
            {
                var existing = db.Categories.FirstOrDefault(x => x.Name == c.name);
                
                if (existing == null)
                {
                    db.Categories.Add(new Category
                    {
                        Name = c.name,
                        Description = c.description
                        // ImageBase64 remains null - Flutter will load from assets based on name
                    });
                    didChange = true;
                }
                else
                {
                    // Update description if needed, preserve existing images
                    if (existing.Description != c.description)
                    {
                        existing.Description = c.description;
                        didChange = true;
                    }
                    // ImageBase64 remains unchanged - preserve uploaded images
                }
            }
            if (didChange) db.SaveChanges();

            // Create mapping from seed IDs to database IDs
            var map = new Dictionary<int, int>();
            foreach (var c in payload.categories)
            {
                var dbCat = db.Categories.FirstOrDefault(x => x.Name == c.name);
                if (dbCat != null) map[c.id] = dbCat.Id;
            }

            // Seed Tools
            foreach (var t in payload.tools)
            {
                var mappedCatId = map.TryGetValue(t.categoryId, out var v) ? v : t.categoryId;
                var existingTool = db.Tools.FirstOrDefault(x => x.Name == t.name);
                
                if (existingTool == null)
                {
                    db.Tools.Add(new Tool
                    {
                        Name = t.name,
                        Description = t.description,
                        CategoryId = mappedCatId,
                        DailyRate = t.dailyPrice,
                        Quantity = 10,
                        IsAvailable = t.available,
                        DepositAmount = 0
                        // ImageBase64 remains null - Flutter will load from assets based on name
                    });
                    didChange = true;
                }
                else
                {
                    if (existingTool.CategoryId != mappedCatId || existingTool.Description != t.description || existingTool.DailyRate != t.dailyPrice || existingTool.IsAvailable != t.available)
                    {
                        existingTool.CategoryId = mappedCatId;
                        existingTool.Description = t.description;
                        existingTool.DailyRate = t.dailyPrice;
                        existingTool.IsAvailable = t.available;
                        didChange = true;
                    }
                    // ImageBase64 remains unchanged - preserve uploaded images
                }
            }

            if (didChange) db.SaveChanges();
        }
    }
}

