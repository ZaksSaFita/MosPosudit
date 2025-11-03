using Microsoft.ML.Data;

namespace MosPosudit.Services.DataBase.Data
{
    // Training data for Matrix Factorization representing user-tool interactions
    public class ToolRating
    {
        [LoadColumn(0)]
        public float UserId { get; set; }

        [LoadColumn(1)]
        public float ToolId { get; set; }

        [LoadColumn(2)]
        public float Label { get; set; }  // Implicit rating (1-5) based on rental frequency
    }

    // Prediction result from Matrix Factorization model
    public class ToolRatingPrediction
    {
        public float Score { get; set; }
    }
}

