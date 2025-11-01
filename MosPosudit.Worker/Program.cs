using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using MosPosudit.Services.DataBase;
using MosPosudit.Worker.Services;

var builder = Host.CreateApplicationBuilder(args);

// Add services to the container
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add Email Service
builder.Services.AddSingleton<EmailService>();

// Add background services
builder.Services.AddHostedService<NotificationWorker>();
builder.Services.AddHostedService<EmailConsumer>();

var host = builder.Build();
host.Run();