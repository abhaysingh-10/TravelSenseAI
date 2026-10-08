import joblib
import pandas as pd
import numpy as np
import os

# Get the absolute path to the project root
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, 'agent', 'models', 'cost_prediction_rf.pkl')
DATA_PATH = os.path.join(BASE_DIR, 'agent', 'dataset', 'data', 'travelsense_india_trips.csv')

# 1. Load the AI Brain
try:
    cost_model = joblib.load(MODEL_PATH)
except Exception as e:
    print(f"Error loading model from {MODEL_PATH}: {e}")
    cost_model = None

# 2. Load the dataset for lookups
try:
    df = pd.read_csv(DATA_PATH)
    destination_lookup = df.drop_duplicates(subset=['destination']).set_index('destination')
except Exception as e:
    print(f"Error loading data from {DATA_PATH}: {e}")
    destination_lookup = pd.DataFrame()

def predict_trip_cost(destination, trip_days, travelers_count, transport_mode, hotel_type, season, traveler_type, user_rating=4.0):
    if cost_model is None:
        raise ValueError("Model not loaded. Check server logs.")
        
    if destination not in destination_lookup.index:
        raise ValueError(f"Unknown destination: {destination}")
        
    dest_data = destination_lookup.loc[destination]
    
    features = cost_model.feature_names_in_
    input_df = pd.DataFrame(columns=features)
    input_df.loc[0] = 0.0 
    
    input_df.at[0, 'distance_km'] = dest_data['distance_km']
    input_df.at[0, 'travel_duration_hours'] = dest_data['travel_duration_hours']
    input_df.at[0, 'trip_days'] = trip_days
    input_df.at[0, 'travelers_count'] = travelers_count
    input_df.at[0, 'user_rating'] = user_rating
    
    categories = [
        f"transport_mode_{transport_mode}",
        f"hotel_type_{hotel_type}",
        f"season_{season}",
        f"zone_{dest_data['zone']}",
        f"category_{dest_data['category']}",
        f"traveler_type_{traveler_type}"
    ]
    
    for cat in categories:
        if cat in features:
            input_df.at[0, cat] = 1.0
            
    predicted_cost = cost_model.predict(input_df)[0]
    return round(predicted_cost, 2)

#  Load the Duration Prediction Model
DURATION_MODEL_PATH = os.path.join(BASE_DIR, 'agent', 'models', 'duration_prediction_rf.pkl')
try:
    duration_model = joblib.load(DURATION_MODEL_PATH)
except Exception as e:
    print(f"Error loading model from {DURATION_MODEL_PATH}: {e}")
    duration_model = None

def predict_trip_duration(destination, total_cost_inr, travelers_count, transport_mode, hotel_type, season, traveler_type, user_rating=4.0):
    if duration_model is None:
        raise ValueError("Duration model not loaded.")
        
    if destination not in destination_lookup.index:
        raise ValueError(f"Unknown destination: {destination}")
        
    dest_data = destination_lookup.loc[destination]
    
    features = duration_model.feature_names_in_
    input_df = pd.DataFrame(columns=features)
    input_df.loc[0] = 0.0 
    
    input_df.at[0, 'distance_km'] = dest_data['distance_km']
    input_df.at[0, 'travel_duration_hours'] = dest_data['travel_duration_hours']
    input_df.at[0, 'total_cost_inr'] = total_cost_inr
    input_df.at[0, 'travelers_count'] = travelers_count
    input_df.at[0, 'user_rating'] = user_rating
    
    categories = [
        f"transport_mode_{transport_mode}",
        f"hotel_type_{hotel_type}",
        f"season_{season}",
        f"zone_{dest_data['zone']}",
        f"category_{dest_data['category']}",
        f"traveler_type_{traveler_type}"
    ]
    
    for cat in categories:
        if cat in features:
            input_df.at[0, cat] = 1.0
            
    predicted_duration = duration_model.predict(input_df)[0]
    return round(predicted_duration) # Return as whole number of days
