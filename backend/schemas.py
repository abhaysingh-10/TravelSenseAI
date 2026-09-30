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
