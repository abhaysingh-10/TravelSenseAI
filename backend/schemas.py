from pydantic import BaseModel

# -----------------
# USER SCHEMAS
# -----------------

# This defines what data the Flutter app must send when a user registers or logs in
class UserCreate(BaseModel):
    email: str
    password: str

# This defines the structure of the token we send back upon successful login
class Token(BaseModel):
    access_token: str
    token_type: str

# -----------------
# TRIP SCHEMAS
# -----------------

from datetime import date
from typing import Optional

class TripBase(BaseModel):
    destination: str
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    budget: Optional[float] = 0.0
    spent: Optional[float] = 0.0
    image_url: Optional[str] = None
    weather_temp: Optional[int] = 25

class TripCreate(TripBase):
    pass

class TripUpdate(TripBase):
    pass

class TripOut(TripBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True
        from_attributes = True

# -----------------
# EXPENSE SCHEMAS
# -----------------

class ExpenseBase(BaseModel):
    trip_id: int
    title: str
    amount: float
    category: str
    date: Optional[date] = None

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseUpdate(ExpenseBase):
    pass

class ExpenseOut(ExpenseBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True
        from_attributes = True
