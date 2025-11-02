using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Services.DataBase.Data
{
    public class RecommendationSettings
    {
        [Key]
        public int Id { get; set; }

        // Home Recommendation Weights (must sum to 100)
        [Required]
        [Range(0, 100)]
        public double HomePopularWeight { get; set; } = 40.0;

        [Required]
        [Range(0, 100)]
        public double HomeContentBasedWeight { get; set; } = 30.0;

        [Required]
        [Range(0, 100)]
        public double HomeTopRatedWeight { get; set; } = 30.0;

        // Cart Recommendation Weights (must sum to 100)
        [Required]
        [Range(0, 100)]
        public double CartFrequentlyBoughtWeight { get; set; } = 60.0;

        [Required]
        [Range(0, 100)]
        public double CartSimilarToolsWeight { get; set; } = 40.0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}

