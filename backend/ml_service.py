import joblib
import pandas as pd
import numpy as np
import os

# Get the absolute path to the project root
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, 'backend', 'ml_data', 'cost_prediction_rf.pkl')
DATA_PATH = os.path.join(BASE_DIR, 'backend', 'ml_data', 'travelsense_india_trips.csv')

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

def predict_trip_cost(destination, trip_days, travelers_count, transport_mode, hotel_type, season, traveler_type, user_rating=4.0, real_distance_km=None):
    if cost_model is None:
        raise ValueError("Model not loaded. Check server logs.")
        
    destination = destination.title().strip()
    if destination not in destination_lookup.index:
        # Fallback to a median destination so the app never crashes
        destination = "Jaipur"

        
    dest_data = destination_lookup.loc[destination]
    
    features = cost_model.feature_names_in_
    input_df = pd.DataFrame(columns=features)
    input_df.loc[0] = 0.0 
    
    if real_distance_km and real_distance_km > 0:
        input_df.at[0, 'distance_km'] = real_distance_km
        input_df.at[0, 'travel_duration_hours'] = round(real_distance_km / 65.0, 2)  # Assume avg 65km/h in India
    else:
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
DURATION_MODEL_PATH = os.path.join(BASE_DIR, 'backend', 'ml_data', 'duration_prediction_rf.pkl')
try:
    duration_model = joblib.load(DURATION_MODEL_PATH)
except Exception as e:
    print(f"Error loading model from {DURATION_MODEL_PATH}: {e}")
    duration_model = None

def predict_trip_duration(destination, total_cost_inr, travelers_count, transport_mode, hotel_type, season, traveler_type, user_rating=4.0):
    if duration_model is None:
        raise ValueError("Duration model not loaded.")
        
    destination = destination.title().strip()
    if destination not in destination_lookup.index:
        # Fallback to a median destination so the app never crashes
        destination = "Jaipur"

        
    dest_data = destination_lookup.loc[destination]
    
    features = duration_model.feature_names_in_
    input_df = pd.DataFrame(columns=features)
    input_df.loc[0] = 0.0 
    
    if real_distance_km and real_distance_km > 0:
        input_df.at[0, 'distance_km'] = real_distance_km
        input_df.at[0, 'travel_duration_hours'] = round(real_distance_km / 65.0, 2)  # Assume avg 65km/h in India
    else:
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


# -----------------
# RECOMMENDATION ENGINE
# -----------------
try:
    # We group by destination to calculate average cost and days
    dest_stats = df.groupby("destination").agg(
        avg_cost=("total_cost_inr", "mean"),
        avg_days=("trip_days", "mean")
    ).reset_index()
except Exception as e:
    print(f"Error calculating dest_stats: {e}")
    dest_stats = pd.DataFrame()

def get_destination_recommendations(traveler_type: str, top_n: int = 3):
    if dest_stats.empty:
        return []
        
    if traveler_type.lower() == "luxury travelers":
        recs = dest_stats.sort_values(by="avg_cost", ascending=False).head(top_n)
    elif traveler_type.lower() == "frequent backpackers":
        recs = dest_stats.sort_values(by="avg_cost", ascending=True).head(top_n)
    else:
        # Standard Travelers (middle ground)
        recs = dest_stats[(dest_stats["avg_cost"] > 30000) & (dest_stats["avg_cost"] < 50000)].head(top_n)
        
        # Fallback if standard filters yield nothing
        if recs.empty:
            recs = dest_stats.head(top_n)
            
    return recs["destination"].tolist()


def segment_traveler(total_trips: int, avg_budget: float) -> str:
    if total_trips == 0:
        return "New Traveler"
        
    if avg_budget > 55000:
        return "Luxury Travelers"
    elif total_trips > 11:
        return "Frequent Backpackers"
    else:
        return "Standard Travelers"


import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# Configure Gemini
GENAI_API_KEY = os.getenv("GEMINI_API_KEY")
if GENAI_API_KEY:
    genai.configure(api_key=GENAI_API_KEY)
else:
    print("WARNING: GEMINI_API_KEY not found in environment.")

def generate_itinerary_with_ai(destination: str, days: int, traveler_type: str = "Standard Traveler") -> str:
    """Calls Gemini API to generate a multi-day itinerary."""
    if not GENAI_API_KEY:
        return "Error: AI generation is currently unavailable (Missing API Key)."
        
    try:
        model = genai.GenerativeModel("gemini-3.8-flash")
        
        prompt = f"""
        You are an expert travel agent. 
        Create a realistic, day-by-day itinerary for a {days}-day trip to {destination}.
        The user's travel style is: {traveler_type}. 
        Keep it concise, actionable, and formatted nicely with bullet points.
        Do not include intro or outro filler text, just the itinerary.
        """
        
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"Gemini API Error: {e}")
        return f"Error generating itinerary for {destination}. Please try again later."

