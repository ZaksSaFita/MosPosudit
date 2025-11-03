namespace MosPosudit.Services.DataBase.Data
{
    // Specifies which recommendation engine to use
    public enum RecommendationEngine
    {
        RuleBased = 0,        // Rule-based system using predefined weights and algorithms
        MachineLearning = 1,  // ML system using Matrix Factorization (requires trained model)
        Hybrid = 2            // Tries ML first, falls back to Rule-Based if needed (recommended)
    }
}

