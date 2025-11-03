using System.ComponentModel.DataAnnotations;

namespace MosPosudit.Services.DataBase.Data
{
    // Stores metadata about trained ML recommendation models (actual .zip files stored in file system)
    public class MLRecommendationModel
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string ModelName { get; set; } = string.Empty;

        [Required]
        [StringLength(500)]
        public string ModelFilePath { get; set; } = string.Empty;

        [Required]
        public int TrainingDataSize { get; set; }

        [Required]
        public DateTime TrainedAt { get; set; } = DateTime.UtcNow;

        public string? TrainingMetrics { get; set; }

        [Required]
        public bool IsActive { get; set; } = false;

        public long ModelFileSizeBytes { get; set; }
    }
}

