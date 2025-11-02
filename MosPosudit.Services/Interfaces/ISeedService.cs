using MosPosudit.Services.DataBase;

namespace MosPosudit.Services.Interfaces
{
    public interface ISeedService
    {
        void SeedIfEmpty(ApplicationDbContext dbContext, string contentRootPath);
        void SeedRecommendationSettingsIfNeeded(ApplicationDbContext db);
    }
}

