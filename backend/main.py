import os
from fastapi import FastAPI
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv()

app = FastAPI(title="TravelSense AI API")

@app.get("/")
def read_root():
    return {"message": "Welcome to TravelSense AI API"}
