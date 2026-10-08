from pydantic import BaseModel

class UserCreate(BaseModel):
    email: str
    password: str

# This defines the structure of the token we send back upon successful login
class Token(BaseModel):
    access_token: str
    token_type: str


from datetime import date as dt_date
from typing import Optional

class TripBase(BaseModel):
    destination: str
    start_date: Optional[dt_date] = None
    end_date: Optional[dt_date] = None
    budget: Optional[float] = 0.0
    spent: Optional[float] = 0.0
    image_url: Optional[str] = None
    weather_temp: Optional[int] = 25

class TripCreate(TripBase):
    pass

class TripUpdate(BaseModel):
    destination: Optional[str] = None
    start_date: Optional[dt_date] = None
    end_date: Optional[dt_date] = None
    budget: Optional[float] = None
    spent: Optional[float] = None
    image_url: Optional[str] = None
    weather_temp: Optional[int] = None

class TripOut(TripBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True
        from_attributes = True


class ExpenseBase(BaseModel):
    trip_id: int
    title: str
    amount: float
    category: str
    date: Optional[dt_date] = None

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseUpdate(BaseModel):
    trip_id: Optional[int] = None
    title: Optional[str] = None
    amount: Optional[float] = None
    category: Optional[str] = None
    date: Optional[dt_date] = None

class ExpenseOut(ExpenseBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True
        from_attributes = True

# -----------------
# ML PREDICTION SCHEMAS
# -----------------
class CostPredictionRequest(BaseModel):
    destination: str
    trip_days: int
    travelers_count: int
    transport_mode: str
    hotel_type: str
    season: str
    traveler_type: str

class CostPredictionResponse(BaseModel):
    predicted_cost_inr: float
