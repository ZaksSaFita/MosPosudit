using MosPosudit.WebAPI.Extensions;

var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel to listen on all interfaces (0.0.0.0) so it's accessible via network IP
// This allows Android emulator and other devices on the network to access the API
// Note: In production, configure HTTPS properly with valid certificates
if (builder.Environment.IsDevelopment())
{
    builder.WebHost.ConfigureKestrel(options =>
    {
        options.ListenAnyIP(5000); // HTTP - development only
        // HTTPS can be enabled if needed, but requires certificate configuration
    });
}

// Configure services
builder.Services.AddApplicationControllers();
builder.Services.AddApplicationServices(builder.Configuration);
builder.Services.AddMapsterConfiguration();
builder.Services.AddJwtAuthentication(builder.Configuration);
builder.Services.AddSwaggerConfiguration();

var app = builder.Build();

// Configure middleware
app.UseApplicationMiddleware();

// Initialize database
await app.InitializeDatabaseAsync(builder.Configuration, builder.Environment.ContentRootPath);

app.Run();
