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

            // PHASE 1: Seed Roles (independent)
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

            // PHASE 2: Seed Users (depends on Roles)
            // Ensure admin user exists with correct email
            var adminUser = db.Users.FirstOrDefault(x => x.Username == "desktop");
            if (adminUser == null)
            {
                db.Users.Add(new User
                {
                    FirstName = "Admin",
                    LastName = "User",
                    Username = "desktop",
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

            // Ensure samo-moze-admin user exists with admin role for desktop login
            var samoMozeAdminUser = db.Users.FirstOrDefault(x => x.Username == "samo-moze-admin");
            if (samoMozeAdminUser == null)
            {
                db.Users.Add(new User
                {
                    FirstName = "Admin",
                    LastName = "Desktop",
                    Username = "samo-moze-admin",
                    Email = "admin@mosposudit.com",
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
            else if (samoMozeAdminUser.RoleId != adminRoleId)
            {
                // Ensure user has admin role
                samoMozeAdminUser.RoleId = adminRoleId;
                samoMozeAdminUser.UpdateDate = now;
                didChange = true;
            }

            // Ensure regular user exists with correct email
            var regularUser = db.Users.FirstOrDefault(x => x.Username == "mobile");
            if (regularUser == null)
            {
                db.Users.Add(new User
                {
                    FirstName = "Regular",
                    LastName = "User",
                    Username = "mobile",
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

            // PHASE 3: Seed Categories (independent)
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

            // PHASE 4: Seed Tools (depends on Categories)
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

            // PHASE 5: Seed recommendation data (depends on Users, Tools, Categories)
            // Seed additional data for recommendation system: users, orders, and reviews
            SeedRecommendationData(db);
        }

        // Seeds recommendation settings with default values if not present
        public void SeedRecommendationSettingsIfNeeded(ApplicationDbContext db)
        {
            try
            {
                // Create default recommendation settings if they don't exist
                if (!db.RecommendationSettings.Any())
                {
                    var defaultSettings = new RecommendationSettings
                    {
                        Engine = RecommendationEngine.MachineLearning,
                        TrainingIntervalDays = 7,
                        HomePopularWeight = 40.0,
                        HomeContentBasedWeight = 30.0,
                        HomeTopRatedWeight = 30.0,
                        CartFrequentlyBoughtWeight = 60.0,
                        CartSimilarToolsWeight = 40.0,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    
                    db.RecommendationSettings.Add(defaultSettings);
                    db.SaveChanges();
                }
            }
            catch (Exception ex)
            {
                // If table doesn't exist yet or any error occurs, skip seeding
                // This is safe - SettingsService.GetRecommendationSettingsAsync will create defaults if needed
                System.Diagnostics.Debug.WriteLine($"Could not seed RecommendationSettings: {ex.Message}");
            }
        }

        private void SeedRecommendationData(ApplicationDbContext db)
        {
            var didChange = false;
            var now = DateTime.UtcNow;
            var userRole = db.Roles.FirstOrDefault(x => x.Name == "User");
            
            if (userRole == null)
                return; // Cannot seed if role doesn't exist

            // Seed additional users - MORE USERS = MORE DIVERSITY for ML
            var additionalUsers = new[]
            {
                new { FirstName = "John", LastName = "Smith", Username = "john", Email = "john.smith@example.com", PhoneNumber = "111222333" },
                new { FirstName = "Sarah", LastName = "Johnson", Username = "sarah", Email = "sarah.johnson@example.com", PhoneNumber = "222333444" },
                new { FirstName = "Mike", LastName = "Williams", Username = "mike", Email = "mike.williams@example.com", PhoneNumber = "333444555" },
                new { FirstName = "Emily", LastName = "Brown", Username = "emily", Email = "emily.brown@example.com", PhoneNumber = "444555666" },
                new { FirstName = "David", LastName = "Davis", Username = "david", Email = "david.davis@example.com", PhoneNumber = "555666777" },
                new { FirstName = "Lisa", LastName = "Wilson", Username = "lisa", Email = "lisa.wilson@example.com", PhoneNumber = "666777888" },
                new { FirstName = "Tom", LastName = "Taylor", Username = "tom", Email = "tom.taylor@example.com", PhoneNumber = "777888999" },
                new { FirstName = "Anna", LastName = "Martinez", Username = "anna", Email = "anna.martinez@example.com", PhoneNumber = "888999000" },
                new { FirstName = "Chris", LastName = "Anderson", Username = "chris", Email = "chris.anderson@example.com", PhoneNumber = "999000111" },
                new { FirstName = "Maria", LastName = "Garcia", Username = "maria", Email = "maria.garcia@example.com", PhoneNumber = "000111222" },
            };

            var userIds = new List<int>();
            var existingUser = db.Users.FirstOrDefault(x => x.Username == "mobile");
            if (existingUser != null)
                userIds.Add(existingUser.Id);

            foreach (var u in additionalUsers)
            {
                var existing = db.Users.FirstOrDefault(x => x.Username == u.Username);
                if (existing == null)
                {
                    var newUser = new User
                    {
                        FirstName = u.FirstName,
                        LastName = u.LastName,
                        Username = u.Username,
                        Email = u.Email,
                        PhoneNumber = u.PhoneNumber,
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword("test"),
                        RoleId = userRole.Id,
                        IsActive = true,
                        CreatedAt = now,
                        UpdateDate = now,
                        PasswordUpdateDate = now
                    };
                    db.Users.Add(newUser);
                    didChange = true;
                }
                else
                {
                    userIds.Add(existing.Id);
                }
            }

            if (didChange)
            {
                db.SaveChanges();
                // Reload users to get IDs
                userIds.Clear();
                userIds.AddRange(db.Users.Where(x => x.RoleId == userRole.Id).Select(x => x.Id).ToList());
            }

            // Get all tools
            var tools = db.Tools.Where(t => t.IsAvailable && t.Quantity > 0).ToList();
            if (!tools.Any())
                return; // Cannot seed orders/reviews without tools

            // Seed orders (rentanije) - spread over last 90 days to make recommendations work
            var random = new Random(42); // Fixed seed for consistency
            var orderCount = 0;
            
            // PHASE 1: Create diverse orders for ML training (more users, more tool variety)
            for (int day = 0; day < 90; day++)
            {
                var orderDate = now.AddDays(-day);
                
                // Create 2-5 orders per day (increased for more diversity)
                var ordersPerDay = random.Next(2, 6); // 2-5 orders
                
                for (int orderIndex = 0; orderIndex < ordersPerDay; orderIndex++)
                {
                    // Pick a user (weighted towards having variety - each user should rent many different tools)
                    var userId = userIds[random.Next(userIds.Count)];
                    var startDate = orderDate.AddDays(random.Next(-7, 0)); // Start date 0-7 days ago
                    var endDate = startDate.AddDays(random.Next(1, 8)); // Rental period 1-7 days
                    var toolIds = new List<int>();
                    
                    // Create more multi-item orders (1-4 tools, with bias towards 2-3 items for cart recommendations)
                    var toolsPerOrder = random.Next(100) < 70 ? random.Next(2, 4) : 1; // 70% multi-item, 30% single item
                    
                    // Create patterns that ML can learn:
                    // - 40% of orders: Tools from same category (learn category preferences)
                    // - 30% of orders: Complementary tools (e.g., drill + drill bits)
                    // - 30% of orders: Random mix
                    var orderPattern = random.Next(100);
                    
                    if (orderPattern < 40 && tools.Any())
                    {
                        // PATTERN 1: Same category (helps learn user category preferences)
                        var firstTool = tools[random.Next(tools.Count)];
                        var categoryTools = tools.Where(t => t.CategoryId == firstTool.CategoryId && t.Id != firstTool.Id).ToList();
                        toolIds.Add(firstTool.Id);
                        
                        for (int i = 1; i < toolsPerOrder && categoryTools.Any(); i++)
                        {
                            var tool = categoryTools[random.Next(categoryTools.Count)];
                            if (!toolIds.Contains(tool.Id))
                            {
                                toolIds.Add(tool.Id);
                                categoryTools.Remove(tool);
                            }
                        }
                    }
                    else if (orderPattern < 70)
                    {
                        // PATTERN 2: Complementary tools (helps learn "frequently bought together")
                        // Pick tools somewhat related (simulate real user behavior)
                        var availableTools = tools.ToList();
                        for (int i = 0; i < toolsPerOrder && availableTools.Any(); i++)
                        {
                            var tool = availableTools[random.Next(availableTools.Count)];
                            toolIds.Add(tool.Id);
                            availableTools.Remove(tool);
                        }
                    }
                    else
                    {
                        // PATTERN 3: Random selection (adds noise for robustness)
                        for (int i = 0; i < toolsPerOrder && tools.Any(); i++)
                        {
                            var tool = tools[random.Next(tools.Count)];
                            if (!toolIds.Contains(tool.Id))
                                toolIds.Add(tool.Id);
                        }
                    }

                    if (toolIds.Any())
                    {
                        // Calculate total amount first
                        decimal totalAmount = 0;
                        var orderItemsToAdd = new List<(int toolId, int quantity, decimal dailyRate, decimal totalPrice)>();
                        
                        foreach (var toolId in toolIds)
                        {
                            var tool = tools.First(t => t.Id == toolId);
                            var quantity = random.Next(1, 4); // 1-3 items
                            var days = (endDate.Date - startDate.Date).Days + 1;
                            var itemTotal = tool.DailyRate * quantity * days;
                            orderItemsToAdd.Add((toolId, quantity, tool.DailyRate, itemTotal));
                            totalAmount += itemTotal;
                        }

                        var order = new Order
                        {
                            UserId = userId,
                            StartDate = startDate.Date,
                            EndDate = endDate.Date,
                            TotalAmount = totalAmount,
                            TermsAccepted = true,
                            ConfirmationEmailSent = true,
                            IsReturned = random.Next(100) < 70, // 70% returned
                            CreatedAt = orderDate
                        };

                        db.Orders.Add(order);
                        db.SaveChanges(); // Save to get order ID

                        // Add order items
                        foreach (var (toolId, quantity, dailyRate, itemTotal) in orderItemsToAdd)
                        {
                            db.OrderItems.Add(new OrderItem
                            {
                                OrderId = order.Id,
                                ToolId = toolId,
                                Quantity = quantity,
                                DailyRate = dailyRate,
                                TotalPrice = itemTotal
                            });
                        }

                        // Add payment (all completed)
                        db.Payments.Add(new Payment
                        {
                            OrderId = order.Id,
                            Amount = totalAmount,
                            PaymentDate = orderDate,
                            IsCompleted = true,
                            CreatedAt = orderDate,
                            TransactionId = $"TXN-{order.Id}-{orderDate:yyyyMMddHHmmss}"
                        });

                        orderCount++;
                        didChange = true;
                    }
                }
            }

            if (didChange)
                db.SaveChanges();

            // Seed reviews for ratings - each tool gets 2-8 reviews from different users
            foreach (var tool in tools)
            {
                var reviewCount = random.Next(2, 9); // 2-8 reviews per tool
                var reviewedUserIds = new HashSet<int>();

                for (int i = 0; i < reviewCount; i++)
                {
                    // Pick random user who hasn't reviewed this tool yet
                    var availableUsers = userIds.Where(u => !reviewedUserIds.Contains(u)).ToList();
                    if (!availableUsers.Any())
                        break; // All users already reviewed

                    var userId = availableUsers[random.Next(availableUsers.Count)];
                    reviewedUserIds.Add(userId);

                    // Rating distribution: mostly 4-5 stars, some 3 stars, rarely 1-2
                    var ratingDistribution = new[] { 1, 1, 2, 2, 3, 3, 4, 4, 4, 5, 5, 5, 5, 5, 5 };
                    var rating = ratingDistribution[random.Next(ratingDistribution.Length)];

                    // Check if review already exists
                    var existingReview = db.Reviews.FirstOrDefault(r => r.UserId == userId && r.ToolId == tool.Id);
                    if (existingReview == null)
                    {
                        var reviewDate = now.AddDays(-random.Next(0, 90)); // Review in last 90 days
                        var comments = new[]
                        {
                            "Great tool, highly recommend!",
                            "Works perfectly for my needs.",
                            "Good quality, would rent again.",
                            "Excellent condition and easy to use.",
                            "Very satisfied with this tool.",
                            "Good value for money.",
                            "Professional quality tool.",
                            "Exceeded my expectations!",
                            null, // Some reviews without comments
                            null,
                        };

                        db.Reviews.Add(new Review
                        {
                            UserId = userId,
                            ToolId = tool.Id,
                            Rating = rating,
                            Comment = rating >= 4 ? comments[random.Next(comments.Length)] : null, // Good ratings have comments
                            CreatedAt = reviewDate
                        });

                        didChange = true;
                    }
                }
            }

            if (didChange)
                db.SaveChanges();
        }
    }
}

