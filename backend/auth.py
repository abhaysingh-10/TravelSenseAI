from passlib.context import CryptContext

# This tells our app to use the "bcrypt" algorithm for hashing passwords
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Takes a plain text password (like 'password123') and checks if it 
    matches the scrambled hash saved in the database.
    """
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """
    Takes a plain text password and returns a scrambled, unreadable string.
    We NEVER save plain text passwords in the database!
    """
    return pwd_context.hash(password)
import os
import jwt
from datetime import datetime, timedelta

# Load our secret key from the .env file to sign the tokens securely
SECRET_KEY = os.getenv("SECRET_KEY", "a_very_long_and_secure_fallback_secret_key_for_jwt_2026")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # Token expires in 7 days

def create_access_token(data: dict):
    """
    Creates a temporary JWT token (like a digital VIP pass) for the user.
    """
    to_encode = data.copy()
    
    # Calculate when this token should expire
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    
    # Generate the actual token string
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
