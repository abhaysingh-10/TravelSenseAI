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
    if expense.trip_id != expense_update.trip_id:
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
