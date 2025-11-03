using MosPosudit.WebAPI.Extensions;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.WebHost.ConfigureKestrel(options =>
    {
        options.ListenAnyIP(5000);
    });
}

builder.Services.AddApplicationControllers();
builder.Services.AddApplicationServices(builder.Configuration);
builder.Services.AddMapsterConfiguration();
builder.Services.AddJwtAuthentication(builder.Configuration);
builder.Services.AddSwaggerConfiguration();

var app = builder.Build();

app.UseApplicationMiddleware();
await app.InitializeDatabaseAsync(builder.Configuration, builder.Environment.ContentRootPath);

app.Run();
