import os
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
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
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

@app.post("/api/ml/predict-cost", response_model=schemas.CostPredictionResponse)
def get_cost_prediction(request: schemas.CostPredictionRequest):
    try:
        from ml_service import predict_trip_cost, destination_lookup, dest_stats
        
        cost = predict_trip_cost(
            destination=request.destination,
            trip_days=request.trip_days,
            travelers_count=request.travelers_count,
            transport_mode=request.transport_mode,
            hotel_type=request.hotel_type,
            season=request.season,
            traveler_type=request.traveler_type
        )
        
        destination = request.destination.title().strip()
        if destination not in destination_lookup.index:
            destination = "Jaipur"
        avg_days_row = dest_stats[dest_stats['destination'] == destination]
        assumed_days = int(round(avg_days_row['avg_days'].values[0])) if not avg_days_row.empty else 4
        
        return {"predicted_cost_inr": round(float(cost), 2), "assumed_days": assumed_days}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="An error occurred during prediction.")

@app.post("/api/ml/predict-duration", response_model=schemas.DurationPredictionResponse)
def get_duration_prediction(request: schemas.DurationPredictionRequest):
    try:
        days = predict_trip_duration(
            destination=request.destination,
            total_cost_inr=request.total_cost_inr,
            travelers_count=request.travelers_count,
            transport_mode=request.transport_mode,
            hotel_type=request.hotel_type,
            season=request.season,
            traveler_type=request.traveler_type
        )
        return {"predicted_trip_days": days}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="An error occurred during prediction.")


from ml_service import get_destination_recommendations

@app.post("/api/ml/recommendations", response_model=schemas.RecommendationResponse)
def get_ml_recommendations(request: schemas.RecommendationRequest, db: Session = Depends(get_db)):
    try:
        # 1. Get destination names from our ML Engine
        rec_names = get_destination_recommendations(request.traveler_type, request.top_n)
        
        # 2. Fetch enriched data (image, description) from PostgreSQL
        destinations = db.query(models.Destination).filter(models.Destination.name.in_(rec_names)).all()
        
        # Build the final response
        results = []
        # Maintain the order of recommendations from the ML engine
        for name in rec_names:
            dest = next((d for d in destinations if d.name == name), None)
            if dest:
                results.append({
                    "name": dest.name,
                    "description": dest.description,
                    "image_url": dest.image_url
                })
            else:
                # Fallback if the destination isn't in DB for some reason
                results.append({
                    "name": name,
                    "description": "A beautiful destination.",
                    "image_url": None
                })
                
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

