using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Model.Requests.Settings
{
    public class RecommendationSettingsUpdateRequest
    {
        [Required]
        public int Engine { get; set; }

        [Required]
        [Range(1, 365)]
        public int TrainingIntervalDays { get; set; }

        [Required]
        [Range(0, 100)]
        public double HomePopularWeight { get; set; }

        [Required]
        [Range(0, 100)]
        public double HomeContentBasedWeight { get; set; }

        [Required]
        [Range(0, 100)]
        public double HomeTopRatedWeight { get; set; }

        [Required]
        [Range(0, 100)]
        public double CartFrequentlyBoughtWeight { get; set; }

        [Required]
        [Range(0, 100)]
        public double CartSimilarToolsWeight { get; set; }
    }
}

