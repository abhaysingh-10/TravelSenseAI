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

@app.post("/trips", response_model=schemas.TripOut)
def create_trip(trip: schemas.TripCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    new_trip = models.Trip(**trip.model_dump(), user_id=current_user.id)
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
