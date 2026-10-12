import os
from typing import Optional, List
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import models, schemas, auth
from database import get_db
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

app = FastAPI(title="TravelSense AI API")

''' CORS CONFIGURATION 
This allows our Flutter app 
 to communicate with this backend without getting blocked by security rules.'''
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace "*" with  app's actual URL
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods like GET, POST, PUT, DELETE
    allow_headers=["*"],  # Allows all headers
)

@app.get("/")
def read_root():
    return {"message": "Welcome to TravelSense AI API"}

# -----------------
# DEPENDENCIES
# -----------------

from fastapi.security import OAuth2PasswordBearer
import jwt

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
        
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

# -----------------
# AUTHENTICATION ENDPOINTS
# -----------------

@app.post("/auth/register", response_model=dict)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Check if the email already exists in our Supabase database
    existing_user = db.query(models.User).filter(models.User.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # 2. Scramble (hash) the plain text password
    hashed_password = auth.get_password_hash(user.password)
    
    # 3. Create a new User record and save it to the database
    new_user = models.User(email=user.email, hashed_password=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user) # Refreshes to get the auto-generated ID from Supabase
    
    return {"message": "User created successfully", "user_id": new_user.id}

@app.post("/auth/login", response_model=schemas.Token)
def login_user(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username.strip().lower()).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = auth.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

# -----------------
# TRIP ENDPOINTS
# -----------------
from typing import List

from services import get_weather_for_city, get_distance_between_cities, get_image_for_city

@app.get("/api/distance")
async def calculate_distance(origin: str, destination: str):
    distance_km = await get_distance_between_cities(origin, destination)
    if distance_km == 0.0:
        raise HTTPException(status_code=400, detail="Could not calculate distance. Check city names or API key.")
    return {"origin": origin, "destination": destination, "distance_km": distance_km}

@app.post("/trips", response_model=schemas.TripOut)
async def create_trip(trip: schemas.TripCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    weather = await get_weather_for_city(trip.destination)
    image_url = await get_image_for_city(trip.destination)
    
    # Dump trip payload and overwrite weather_temp and image_url
    trip_data = trip.model_dump()
    trip_data['weather_temp'] = int(round(weather))
    if image_url:
        trip_data['image_url'] = image_url
    
    new_trip = models.Trip(**trip_data, user_id=current_user.id)
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)
    return new_trip

@app.get("/trips", response_model=List[schemas.TripOut])
def get_trips(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    trips = db.query(models.Trip).filter(models.Trip.user_id == current_user.id).all()
    return trips

@app.put("/trips/{trip_id}", response_model=schemas.TripOut)
def update_trip(trip_id: int, trip_update: schemas.TripUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    trip = db.query(models.Trip).filter(models.Trip.id == trip_id, models.Trip.user_id == current_user.id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    
    for key, value in trip_update.model_dump(exclude_unset=True).items():
        setattr(trip, key, value)
        
    db.commit()
    db.refresh(trip)
    return trip

@app.delete("/trips/{trip_id}")
def delete_trip(trip_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    trip = db.query(models.Trip).filter(models.Trip.id == trip_id, models.Trip.user_id == current_user.id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    
    db.delete(trip)
    db.commit()
    return {"detail": "Trip deleted successfully"}

# -----------------
# EXPENSE ENDPOINTS
# -----------------

@app.post("/expenses", response_model=schemas.ExpenseOut)
def create_expense(expense: schemas.ExpenseCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Verify that the trip actually exists and belongs to the user
    trip = db.query(models.Trip).filter(models.Trip.id == expense.trip_id, models.Trip.user_id == current_user.id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    new_expense = models.Expense(**expense.model_dump(), user_id=current_user.id)
    db.add(new_expense)
    
    # Optionally update the trip's spent amount automatically
    trip.spent = (trip.spent or 0.0) + expense.amount
    
    db.commit()
    db.refresh(new_expense)
    return new_expense

@app.get("/expenses", response_model=List[schemas.ExpenseOut])
def get_expenses(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    expenses = db.query(models.Expense).filter(models.Expense.user_id == current_user.id).all()
    return expenses

@app.put("/expenses/{expense_id}", response_model=schemas.ExpenseOut)
def update_expense(expense_id: int, expense_update: schemas.ExpenseUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    expense = db.query(models.Expense).filter(models.Expense.id == expense_id, models.Expense.user_id == current_user.id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    
    # Verify the new trip_id belongs to the user if it's being changed
    if expense_update.trip_id is not None and expense.trip_id != expense_update.trip_id:
        trip = db.query(models.Trip).filter(models.Trip.id == expense_update.trip_id, models.Trip.user_id == current_user.id).first()
        if not trip:
            raise HTTPException(status_code=404, detail="Target trip not found")

    # Handle trip spent adjustment
    old_amount = expense.amount
    old_trip_id = expense.trip_id
    
    for key, value in expense_update.model_dump(exclude_unset=True).items():
        setattr(expense, key, value)
        
    # Adjust spent amounts if needed
    if old_trip_id == expense.trip_id:
        trip = db.query(models.Trip).filter(models.Trip.id == expense.trip_id).first()
        trip.spent = (trip.spent or 0.0) - old_amount + expense.amount
    else:
        old_trip = db.query(models.Trip).filter(models.Trip.id == old_trip_id).first()
        old_trip.spent = (old_trip.spent or 0.0) - old_amount
        new_trip = db.query(models.Trip).filter(models.Trip.id == expense.trip_id).first()
        new_trip.spent = (new_trip.spent or 0.0) + expense.amount

    db.commit()
    db.refresh(expense)
    return expense

@app.delete("/expenses/{expense_id}")
def delete_expense(expense_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    expense = db.query(models.Expense).filter(models.Expense.id == expense_id, models.Expense.user_id == current_user.id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    
    # Adjust the trip's spent amount
    trip = db.query(models.Trip).filter(models.Trip.id == expense.trip_id).first()
    if trip:
        trip.spent = (trip.spent or 0.0) - expense.amount

    db.delete(expense)
    db.commit()
    return {"detail": "Expense deleted successfully"}

# -----------------
# ML ENDPOINTS (PHASE 4)
# -----------------
from ml_service import predict_trip_cost, predict_trip_duration


def normalize_destination(dest: str, lookup_index) -> str:
    dest = dest.title().strip()
    if dest in lookup_index:
        return dest
    # Try splitting by comma
    first_part = dest.split(',')[0].strip()
    if first_part in lookup_index:
        return first_part
    # Try checking if any known destination is a substring
    for known in lookup_index:
        if known.lower() in dest.lower():
            return known
    return "Jaipur" # Fallback

@app.post("/api/ml/predict-cost", response_model=schemas.CostPredictionResponse)
async def get_cost_prediction(request: schemas.CostPredictionRequest):
    try:
        from ml_service import predict_trip_cost, destination_lookup, dest_stats
        
        
        normalized_dest = normalize_destination(request.destination, destination_lookup.index)
        avg_days_row = dest_stats[dest_stats['destination'] == normalized_dest]
        assumed_days = int(round(avg_days_row['avg_days'].values[0])) if not avg_days_row.empty else 4
        
        real_distance = None
        if request.source and request.destination:
            from services import get_distance_between_cities
            # OpenRouteService call
            dist = await get_distance_between_cities(request.source, request.destination)
            if dist and dist > 0:
                real_distance = dist
        
        # Use assumed_days if flutter doesn't provide trip_days
        actual_days = request.trip_days if request.trip_days else assumed_days
        
        
        # Map Flutter labels to dataset labels
        hotel_mapping = {
            "Budget": "Budget Hotel",
            "Standard": "Mid-Range 3-Star",
            "Luxury": "Luxury Resort"
        }
        mapped_hotel = hotel_mapping.get(request.hotel_type, request.hotel_type)

        cost = predict_trip_cost(
            destination=request.destination,
            trip_days=actual_days,
            travelers_count=request.travelers_count,
            transport_mode=request.transport_mode,
            hotel_type=mapped_hotel,
            season=request.season,
            traveler_type=request.traveler_type,
            real_distance_km=real_distance
        )
        
        return {"predicted_cost_inr": round(float(cost), 2), "assumed_days": actual_days}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="An error occurred during prediction.")

@app.post("/api/ml/predict-duration", response_model=schemas.DurationPredictionResponse)
def get_duration_prediction(request: schemas.DurationPredictionRequest):
    try:
        hotel_mapping = {
            "Budget": "Budget Hotel",
            "Standard": "Mid-Range 3-Star",
            "Luxury": "Luxury Resort"
        }
        mapped_hotel = hotel_mapping.get(request.hotel_type, request.hotel_type)

        days = predict_trip_duration(
            destination=request.destination,
            total_cost_inr=request.total_cost_inr,
            travelers_count=request.travelers_count,
            transport_mode=request.transport_mode,
            hotel_type=mapped_hotel,
            season=request.season,
            traveler_type=request.traveler_type
        )
        return {"predicted_trip_days": days}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="An error occurred during prediction.")


from ml_service import get_destination_recommendations, dest_stats, segment_traveler

RECOMMENDED_DURATIONS = {
    "Agra": 3,
    "Alleppey": 3,
    "Bandipur": 3,
    "Chikmagalur": 4,
    "Goa": 4,
    "Jaipur": 4,
    "Munnar": 4,
    "Manali": 4,
    "Ooty": 3,
    "Varanasi": 3,
    "Gokarna": 3,
    "Pondicherry": 3,
    "Puri": 3,
    "Amritsar": 3,
    "Srinagar": 4,
    "Spiti Valley": 5,
    "Kodaikanal": 3,
    "Mussoorie": 3,
    "Shillong": 4,
    "Havelock Island": 4,
    "Rameshwaram": 3,
    "Mysore": 3,
    "Madurai": 3,
    "Kaziranga": 3,
    "Pushkar": 3,
    "Kovalam": 3,
    "Bodh Gaya": 3,
    "Khajuraho": 3,
    "Tirupati": 2,
    "Wayanad": 3,
    "Gangtok": 4,
}

def _enrich_recommendations(rec_names: list, traveler_type: str, db: Session, preferences: list = None):
    destinations = db.query(models.Destination).filter(models.Destination.name.in_(rec_names)).all()
    results = []
    scores = [0.96, 0.93, 0.89, 0.86, 0.83]
    
    for i, name in enumerate(rec_names):
        dest = next((d for d in destinations if d.name == name), None)
        stat = dest_stats[dest_stats['destination'] == name] if not dest_stats.empty else pd.DataFrame()
        cost = float(stat['avg_cost'].values[0]) if not stat.empty else 30000.0
        cat = str(stat['category'].values[0]).lower() if (not stat.empty and 'category' in stat.columns) else ""
        days = RECOMMENDED_DURATIONS.get(name, max(3, int(round(stat['avg_days'].values[0])) if not stat.empty else 3))
        
        score = scores[i] if i < len(scores) else 0.82
        desc = dest.description if dest and dest.description else f"An extraordinary destination known for scenic beauty and rich culture in {name}."
        img = dest.image_url if dest and dest.image_url else "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80"
        
        # Personalized AI reason matching preference / category
        if any(kw in cat for kw in ['hill station', 'mountain', 'himalayan', 'valley', 'tea', 'coffee']):
            reason = f"Curated for your passion for mountain vistas, tea gardens, and scenic peaks in {name}."
        elif any(kw in cat for kw in ['beach', 'coastal', 'backwaters', 'cliff', 'scuba']):
            reason = f"Matches your coastal preferences with relaxing waters, beaches, and sea breeze in {name}."
        elif any(kw in cat for kw in ['heritage', 'spiritual', 'culture', 'temple', 'monument', 'palace']):
            reason = f"Handpicked for your interest in historical landmarks, culture, and architecture in {name}."
        elif any(kw in cat for kw in ['wildlife', 'safari', 'nature']):
            reason = f"Perfect for wildlife encounters, jungle trails, and nature adventures in {name}."
        elif traveler_type == "Luxury Travelers":
            reason = f"Curated for luxury explorers with premium resorts and stays in {name}."
        elif traveler_type == "Frequent Backpackers":
            reason = f"Matches your backpacking profile with high adventure and budget exploration in {name}."
        else:
            reason = f"Curated for balanced exploration and rich cultural sights in {name}."
            
        results.append({
            "id": f"rec_{i+1}",
            "name": name,
            "description": desc,
            "image_url": img,
            "match_score": score,
            "reason": reason,
            "estimated_budget": round(cost, 2),
            "duration_days": days
        })
    return results

@app.get("/api/ml/recommendations", response_model=schemas.RecommendationResponse)
def get_ml_recommendations_get(
    top_n: int = 3,
    traveler_type: Optional[str] = None,
    preferences: Optional[str] = None,
    db: Session = Depends(get_db),
    token: Optional[str] = Depends(OAuth2PasswordBearer(tokenUrl="auth/login", auto_error=False))
):
    try:
        user_segment = traveler_type
        if not user_segment and token:
            try:
                payload = jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
                email = payload.get("sub")
                if email:
                    user = db.query(models.User).filter(models.User.email == email).first()
                    if user:
                        trips = db.query(models.Trip).filter(models.Trip.user_id == user.id).all()
                        total_trips = len(trips)
                        avg_budget = sum([t.budget for t in trips]) / total_trips if total_trips > 0 else 0.0
                        user_segment = segment_traveler(total_trips=total_trips, avg_budget=avg_budget)
            except Exception:
                pass
                
        if not user_segment or user_segment == "New Traveler":
            user_segment = "Standard Travelers"
            
        pref_list = [p.strip() for p in preferences.split(',') if p.strip()] if preferences else []
        rec_names = get_destination_recommendations(user_segment, top_n, pref_list)
        results = _enrich_recommendations(rec_names, user_segment, db, pref_list)
        return {"traveler_type": user_segment, "recommendations": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/ml/recommendations", response_model=schemas.RecommendationResponse)
def get_ml_recommendations(request: schemas.RecommendationRequest, db: Session = Depends(get_db)):
    try:
        rec_names = get_destination_recommendations(request.traveler_type, request.top_n, request.preferences)
        results = _enrich_recommendations(rec_names, request.traveler_type, db, request.preferences)
        return {"traveler_type": request.traveler_type, "recommendations": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



from ml_service import segment_traveler

@app.get("/api/ml/segmentation", response_model=schemas.SegmentationResponse)
def get_user_segmentation(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    try:
        # Fetch all trips for the current user
        trips = db.query(models.Trip).filter(models.Trip.user_id == current_user.id).all()
        
        total_trips = len(trips)
        avg_budget = 0.0
        
        if total_trips > 0:
            total_budget = sum((trip.budget or 0.0) for trip in trips)
            avg_budget = total_budget / total_trips
            
        # Get the segment from the ML logic
        segment = segment_traveler(total_trips, avg_budget)
        
        return {
            "total_trips": total_trips,
            "avg_budget": round(avg_budget, 2),
            "traveler_segment": segment
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



from ml_service import generate_itinerary_with_ai

@app.post("/api/ml/generate-itinerary", response_model=schemas.GenerateItineraryResponse)
def generate_itinerary(request: schemas.GenerateItineraryRequest, db: Session = Depends(get_db)):
    try:
        itinerary_text = generate_itinerary_with_ai(
            destination=request.destination,
            days=request.days,
            traveler_type=request.traveler_type
        )
        
        return {
            "destination": request.destination,
            "days": request.days,
            "itinerary_text": itinerary_text
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



@app.get("/api/analytics/dashboard", response_model=schemas.DashboardAnalytics)
def get_dashboard_analytics(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    try:
        import datetime
        
        # Get overall totals
        trips = db.query(models.Trip).filter(models.Trip.user_id == current_user.id).all()
        total_trips = len(trips)
        totalLifetimeSpent = sum((t.spent or 0.0) for t in trips)
        averageCostPerTrip = (totalLifetimeSpent / total_trips) if total_trips > 0 else 0.0
        
        # Category Breakdown
        expenses = db.query(models.Expense).filter(models.Expense.user_id == current_user.id).all()
        
        spendingByCategory = {}
        for exp in expenses:
            cat = exp.category or "Other"
            spendingByCategory[cat] = spendingByCategory.get(cat, 0.0) + (exp.amount or 0.0)
            
        # Monthly Trends (Last 6 Months)
        monthlySpending = {}
        today = datetime.date.today()
        
        for i in range(5, -1, -1):
            m = today.month - i
            y = today.year
            if m <= 0:
                m += 12
                y -= 1
            d = datetime.date(y, m, 1)
            month_str = d.strftime("%b") # e.g. "Jan", "Feb" matching Flutter dummy data
            monthlySpending[month_str] = 0.0
            
        for trip in trips:
            if trip.start_date:
                m_str = trip.start_date.strftime("%b")
                if m_str in monthlySpending:
                    monthlySpending[m_str] += (trip.spent or 0.0)
                    
        return {
            "totalTrips": total_trips,
            "totalLifetimeSpent": round(totalLifetimeSpent, 2),
            "averageCostPerTrip": round(averageCostPerTrip, 2),
            "spendingByCategory": spendingByCategory,
            "monthlySpending": monthlySpending
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

