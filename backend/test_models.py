import joblib
import pandas as pd

print(" Testing ML Pipeline ")

try:
    print("1. Loading Cost Prediction Model...")
    cost_model = joblib.load('../agent/models/cost_prediction_rf.pkl')
    print("Cost Prediction Model loaded successfully!")
    
    print("\n2. Loading Duration Prediction Model...")
    duration_model = joblib.load('../agent/models/duration_prediction_rf.pkl')
    print(" Duration Prediction Model loaded successfully!")
    
    print("\n Feature Format Verification (Task 2) ")
    print("Cost Model expects these exact columns in this exact order:")
    print(cost_model.feature_names_in_)
    
except Exception as e:
    print(f" ERROR Loading Models: {e}")
