# ML Recommendation Models

This folder contains **pre-trained Machine Learning models** for the recommendation system.

## What's Inside

- **recommendation_model_YYYYMMDD_HHMMSS.zip** - Trained Matrix Factorization models
- Models are automatically created by the Worker service during training
- Models are loaded by the API service for fast predictions


✅ **Pre-trained model included** - No need to wait for training!  
✅ **Just run:** `docker-compose up -d`  
✅ **ML recommendations work immediately**

## Model Information

- **Algorithm:** Matrix Factorization (Collaborative Filtering)
- **Library:** ML.NET 4.0.3
- **Training Data:** ~300-500 user-tool interactions
- **File Size:** ~3-5 KB (compressed)
- **Training Frequency:** Every 7 days (configurable)

## Switching Between Modes

Use the Desktop App:
1. **Settings → Recommendations Settings**
2. Choose:
   - **Rule-Based** - Traditional hardcoded rules
   - **Machine Learning** - Pure ML predictions
   - **Hybrid** - ML with fallback (recommended)

## Manual Training

To retrain the model:
1. Desktop App → Settings → Click **"Train Now"**
2. Or wait for scheduled training (every 7 days)
3. New model will be saved here automatically

---


