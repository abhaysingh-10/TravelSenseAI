import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

app = FastAPI(title="TravelSense AI API")

# --- CORS CONFIGURATION ---
# This allows your Flutter app (which might run on a mobile emulator or web) 
# to communicate with this backend without getting blocked by security rules.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, you would replace "*" with your app's actual URL
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods like GET, POST, PUT, DELETE
    allow_headers=["*"],  # Allows all headers
)

@app.get("/")
def read_root():
    return {"message": "Welcome to TravelSense AI API"}
