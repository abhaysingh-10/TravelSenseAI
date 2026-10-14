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
        
    # Normalize destination
    original = destination.title().strip()
    destination = "Jaipur"
    if original in destination_lookup.index:
        destination = original
    else:
        first_part = original.split(',')[0].strip()
        if first_part in destination_lookup.index:
            destination = first_part
        else:
            for known in destination_lookup.index:
                if known.lower() in original.lower():
                    destination = known
                    break

        
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

def predict_trip_duration(destination, total_cost_inr, travelers_count, transport_mode, hotel_type, season, traveler_type, user_rating=4.0, real_distance_km=None):
    if duration_model is None:
        raise ValueError("Duration model not loaded.")
        
    # Normalize destination
    original = destination.title().strip()
    destination = "Jaipur"
    if original in destination_lookup.index:
        destination = original
    else:
        first_part = original.split(',')[0].strip()
        if first_part in destination_lookup.index:
            destination = first_part
        else:
            for known in destination_lookup.index:
                if known.lower() in original.lower():
                    destination = known
                    break

        
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
import random

PREFERENCE_KEYWORDS = {
    'mountains': ['hill station', 'mountain', 'himalayan', 'valley', 'tea', 'coffee'],
    'beaches': ['beach', 'coastal', 'backwaters', 'scuba', 'cliff'],
    'history & culture': ['heritage', 'spiritual', 'culture', 'pilgrimage', 'buddhist', 'temple', 'archaeology', 'monument', 'palace'],
    'culture': ['heritage', 'spiritual', 'culture', 'pilgrimage', 'buddhist', 'temple', 'archaeology', 'monument', 'palace'],
    'road trips': ['adventure', 'nature', 'mountain', 'valley', 'waterfalls', 'wildlife', 'coffee'],
    'luxury': ['resort', 'palace', 'luxury', 'romance', 'wellness', 'heritage & palaces', 'beach & nightlife'],
    'backpacking': ['adventure', 'spiritual', 'beach & spiritual', 'heritage & archaeology', 'cliff'],
    'food & culinary': ['heritage & culture', 'french heritage', 'coastal', 'backwaters'],
    'urban exploration': ['heritage & culture', 'heritage & monument', 'heritage & palaces']
}

try:
    # We group by destination to calculate average cost, days, and keep primary category
    dest_stats = df.groupby("destination").agg(
        category=("category", "first"),
        avg_cost=("total_cost_inr", "mean"),
        avg_days=("trip_days", "mean")
    ).reset_index()
except Exception as e:
    print(f"Error calculating dest_stats: {e}")
    dest_stats = pd.DataFrame()

CURATED_DESTINATIONS = {
    'Munnar', 'Agra', 'Mysore', 'Kaziranga', 'Kodaikanal', 'Gangtok',
    'Tirupati', 'Mussoorie', 'Havelock Island', 'Bodh Gaya', 'Puri',
    'Varanasi', 'Shillong', 'Ooty', 'Khajuraho', 'Amritsar', 'Wayanad',
    'Srinagar', 'Bandipur', 'Pondicherry', 'Pushkar', 'Jaipur', 'Kovalam',
    'Alleppey', 'Goa', 'Rameshwaram', 'Madurai', 'Spiti Valley',
    'Chikmagalur', 'Manali', 'Gokarna'
}

def get_destination_recommendations(traveler_type: str, top_n: int = 3, preferences: list = None):
    if dest_stats.empty:
        return []
        
    candidates = dest_stats.copy()
    
    # 1. Filter by preferences if provided
    if preferences and len(preferences) > 0:
        keywords = []
        for p in preferences:
            clean_p = p.lower().strip()
            if clean_p in PREFERENCE_KEYWORDS:
                keywords.extend(PREFERENCE_KEYWORDS[clean_p])
            else:
                keywords.append(clean_p)
                
        pref_matches = candidates[candidates['category'].str.lower().apply(
            lambda cat: any(kw in str(cat) for kw in keywords)
        )]
        if not pref_matches.empty:
            candidates = pref_matches

    # 2. Prioritize destinations that have rich database descriptions & HD photography
    curated_matches = candidates[candidates['destination'].isin(CURATED_DESTINATIONS)]
    if not curated_matches.empty and len(curated_matches) >= top_n:
        candidates = curated_matches

    # 3. Segment tuning if pool is sufficiently large
    if traveler_type.lower() == "luxury travelers":
        luxury_pool = candidates[candidates["avg_cost"] > 40000]
        if not luxury_pool.empty and len(luxury_pool) >= top_n:
            candidates = luxury_pool
    elif traveler_type.lower() == "frequent backpackers":
        bp_pool = candidates[candidates["avg_cost"] < 35000]
        if not bp_pool.empty and len(bp_pool) >= top_n:
            candidates = bp_pool
    elif traveler_type.lower() == "standard travelers":
        std_pool = candidates[(candidates["avg_cost"] >= 25000) & (candidates["avg_cost"] <= 55000)]
        if not std_pool.empty and len(std_pool) >= top_n:
            candidates = std_pool
            
    dest_list = candidates["destination"].tolist()
    if not dest_list:
        dest_list = dest_stats["destination"].tolist()
        
    # 4. Dynamic Rotation: Sample top_n distinct destinations randomly on each call
    sample_size = min(top_n, len(dest_list))
    return random.sample(dest_list, sample_size)


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
    """Calls Gemini API with resilient multi-model failover to generate a multi-day itinerary."""
    if not GENAI_API_KEY:
        return _get_fallback_itinerary(destination, days, traveler_type)
        
    models_to_try = [
        "gemini-3.5-flash",
        "gemini-flash-lite-latest",
        "gemini-3.7-flash",
        "gemini-3.1-flash-lite",
        "gemini-3.5-flash-lite",
    ]
    
    prompt = f"""
    You are an expert travel concierge. 
    Create a comprehensive, highly engaging day-by-day itinerary for a {days}-day trip to {destination}.
    The user's travel style is: {traveler_type}. 

    For EACH day (Day 1 through Day {days}), provide 2 to 3 distinct, high-value activities for Morning, Afternoon, and Evening. Include specific landmark names, regional food or restaurant recommendations, and viewpoints.

    Format strictly as:
    Day 1: [Catchy Area Focus / Theme]
    - Morning:
      - [Activity 1: Landmark or primary highlight]
      - [Activity 2: Coffee, breakfast spot, or secondary sight]
    - Afternoon:
      - [Activity 1: Local lunch recommendation]
      - [Activity 2: Afternoon attraction or scenic experience]
    - Evening:
      - [Activity 1: Sunset spot or cultural walk]
      - [Activity 2: Authentic dinner recommendation or night activity]

    Repeat this detailed structure for all {days} days. Do not skip days. Do not include introductory or closing filler text, just the itinerary.
    """
    
    for model_name in models_to_try:
        try:
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(prompt)
            if response and response.text:
                return response.text.strip()
        except Exception as e:
            print(f"Gemini API Error with {model_name}: {e}")
            continue

    # Graceful fallback itinerary if all API quotas or models are temporarily saturated
    return _get_fallback_itinerary(destination, days, traveler_type)


def _get_fallback_itinerary(destination: str, days: int, traveler_type: str) -> str:
    """Provides a realistic curated itinerary if external AI endpoints hit rate limits."""
    lines = []
    themes = [
        ("Arrival, Historic Center & Heritage", "historic district and central squares", "traditional local bistro", "iconic landmark walking tour", "picturesque sunset viewpoint"),
        ("Nature, Scenic Overlooks & Exploration", "scenic gardens and nature trails", "popular neighborhood eatery", "famous cultural museum and architectural sights", "vibrant nightlife and dining area"),
        ("Local Culture, Markets & Hidden Gems", "bustling local market and artisan boutiques", "street food tasting tour", "coastal or riverfront promenade", "panoramic farewell dinner with skyline views"),
    ]
    
    for d in range(1, days + 1):
        theme_idx = (d - 1) % len(themes)
        title, morning_sight, lunch_spot, afternoon_sight, evening_spot = themes[theme_idx]
        lines.append(f"Day {d}: {destination} {title}")
        lines.append("- Morning:")
        lines.append(f"  - Check in and explore the {morning_sight}.")
        lines.append(f"  - Savor a morning coffee and breakfast at a local cafe.")
        lines.append("- Afternoon:")
        lines.append(f"  - Enjoy authentic regional cuisine at a {lunch_spot}.")
        lines.append(f"  - Embark on the {afternoon_sight}.")
        lines.append("- Evening:")
        lines.append(f"  - Unwind at the {evening_spot}.")
        lines.append(f"  - Savor dinner featuring regional specialties of {destination}.")
        lines.append("")
        
    return "\n".join(lines).strip()

