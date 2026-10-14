# TravelSense AI
### Smart Travel Planning and Expense Management Powered by Machine Learning and Generative AI

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Supabase-336791?logo=postgresql)](https://supabase.com)
[![Scikit-Learn](https://img.shields.io/badge/ML-Scikit--Learn-F7931E?logo=scikitlearn)](https://scikit-learn.org)
[![Gemini](https://img.shields.io/badge/AI-Google_Gemini-4285F4?logo=google)](https://ai.google.dev)

---

## Executive Overview

TravelSense AI is an end-to-end mobile travel platform engineered to streamline trip planning, cost estimation, and expense management. By synthesizing predictive regression models, unsupervised behavioral clustering, and large language model (LLM) orchestration, the system provides real-time budget forecasting, style-driven destination curation, custom multi-day itineraries, and quantitative spending analytics.

---

## Key System Modules

### 1. Predictive Machine Learning Engine
* **Cost Estimation**: Trained Random Forest Regressor estimates total trip expenditure based on origin, destination, distance, traveler count, accommodation tier, transport mode, and season.
* **Duration Forecasting**: Predicts optimal trip length in days to balance travel comfort against user budget constraints.
* **Geospatial Distance Routing**: Integrates OpenRouteService (ORS) to calculate highway travel distance between source and destination cities.

### 2. Destination Recommendation Engine
* **Content-Based Filtering**: Recommends destinations from a curated dataset of 31 Indian travel locations matched against user preferences and spending style.
* **Multi-Tier Asset Architecture**: Integrates local offline image assets with network fallbacks, ensuring zero-latency rendering and offline continuity.

### 3. Generative AI Itinerary Synthesizer
* **Personalized Schedules**: Leverages Google Gemini to dynamically construct detailed daily itineraries based on user travel persona.
* **Granular Day Planning**: Structures each day into distinct Morning, Afternoon, and Evening activities, highlighting regional landmarks, authentic local cuisine, and transit routes.
* **In-Memory Caching & Failover**: Eliminates redundant network calls by caching generated plans in client memory and maintaining pre-computed fallbacks for low-connectivity environments.

### 4. Financial Analytics and ML Budget Efficiency
* **Visual Data Analytics**: Interactive data visualization powered by FL Chart, displaying cumulative spending trends and categorical distribution.
* **Machine Learning Budget Benchmarking**: Evaluates actual spending against regression baseline predictions to generate efficiency scores and net savings metrics.
* **Real-Time Synchronization**: Pull-to-refresh architecture ensures synchronized state across trips, expenses, and analytics.

### 5. Traveler Behavioral Segmentation
* **K-Means Clustering**: Analyzes historical frequency, duration, and budget metrics to classify users into distinct behavioral clusters (Luxury Travelers, Frequent Backpackers, Standard Travelers, Occasional Vacationers).
* **Profile Integration**: Computes and displays dynamic traveler badges on user profiles.

### 6. Trip and Expense Lifecycle Management
* Full CRUD operations for trips and categorized expenditures (Accommodation, Food, Transport, Sightseeing, Shopping).
* Real-time budget progress tracking, remaining balance calculations, and integrated weather forecasting via OpenWeatherMap.

---

## System Architecture

```mermaid
flowchart TD
    subgraph Client ["Client Layer (Flutter Mobile App)"]
        UI["Riverpod UI State Management\n(Screens, Custom Widgets, FL Charts)"]
        Cache["In-Memory Cache & Local Assets"]
        Storage["Secure Storage (JWT & Session)"]
    end

    subgraph Backend ["Application Layer (FastAPI on Render)"]
        API["FastAPI REST Router"]
        Security["Authentication & JWT Verification"]
        MLService["Machine Learning Inference Service"]
        ExternalServices["Weather & Distance Services"]
    end

    subgraph Infrastructure ["Data & Intelligence Layer"]
        Postgres[(PostgreSQL on Supabase)]
        RFCost["Cost Prediction Model (.pkl)"]
        RFDuration["Duration Prediction Model (.pkl)"]
        KMeansModel["Traveler Clustering Model"]
        GeminiLLM["Google Gemini Generative AI"]
    end

    UI -->|HTTPS / REST API| API
    API --> Security
    API --> MLService
    API --> ExternalServices
    API --> Postgres
    MLService --> RFCost
    MLService --> RFDuration
    MLService --> KMeansModel
    MLService --> GeminiLLM
```

---

## Technology Stack

| Layer | Technologies / Frameworks | Purpose |
| :--- | :--- | :--- |
| **Mobile Client** | Flutter 3.x, Dart | Cross-platform mobile application interface |
| **State Management** | Riverpod 2.x | Reactive dependency injection and provider caching |
| **Data Visualization** | `fl_chart`, Google Fonts | Financial trend graphs and typography design system |
| **Backend API** | FastAPI, Python 3.9+, Uvicorn | Asynchronous RESTful API microservice |
| **Database** | PostgreSQL via Supabase | Relational data persistence for users, trips, and expenses |
| **ORM & Migrations** | SQLAlchemy, Alembic | Schema definition and database migrations |
| **Machine Learning** | Scikit-learn, Pandas, NumPy | Regression modeling and unsupervised clustering |
| **Generative AI** | Google Gemini API | Dynamic day-by-day itinerary generation |
| **External Services** | OpenWeatherMap, OpenRouteService | Live weather forecasts and geospatial distance routing |
| **Deployment** | Render (API), Supabase (Database) | Production cloud hosting and continuous deployment |

---

## Directory Structure

```
TravelSenseAI/
├── backend/                        # FastAPI REST API backend service
│   ├── main.py                     # Application entrypoint & route handlers
│   ├── models.py                   # SQLAlchemy database entity models
│   ├── schemas.py                  # Pydantic validation schemas
│   ├── database.py                 # PostgreSQL connection pool configuration
│   ├── auth.py                     # JWT token handling & bcrypt password hashing
│   ├── ml_service.py               # ML inference, recommendations & Gemini integration
│   ├── services.py                 # External API integrations (Weather, Distance)
│   ├── ml_data/                    # Serialized .pkl models and reference datasets
│   └── requirements.txt            # Python dependencies
│
├── frontend/                       # Flutter cross-platform mobile client
│   ├── lib/
│   │   ├── main.dart               # Flutter application entrypoint
│   │   ├── models/                 # Strongly typed data models
│   │   ├── providers/              # Riverpod state notifiers & cached providers
│   │   ├── screens/                # Modular domain-specific screen folders
│   │   │   ├── auth/               # Splash, Onboarding, Login, Register
│   │   │   ├── trips/              # Home list, Add/Edit trip, Trip details
│   │   │   ├── expenses/           # Add/Edit expense
│   │   │   ├── destinations/       # Recommendations, Destination details
│   │   │   ├── predictor/          # Trip cost & duration predictor
│   │   │   ├── dashboard/          # Analytics dashboard & charts
│   │   │   ├── profile/            # User profile & segment badge
│   │   │   ├── main_screen.dart    # Root navigation shell
│   │   │   └── screens.dart        # Unified barrel export
│   │   ├── services/               # API service & secure storage client
│   │   ├── theme/                  # Theme tokens, palette, and typography
│   │   └── widgets/                # Reusable UI widgets & recommendation carousel
│   └── assets/images/destinations/ # 31 high-resolution destination assets
│
├── notebooks/                      # Data engineering and ML training pipeline
│   ├── 01_data_cleaning.ipynb      # Outlier treatment and missing value imputation
│   ├── 02_eda.ipynb                # Feature correlation and distribution analysis
│   ├── 03_feature_engineering.ipynb# Encoding, transformation, and train-test splits
│   ├── 04_model_training.ipynb     # Cost prediction model training and cross-validation
│   ├── 05_duration_prediction.ipynb# Duration prediction model training
│   ├── 06_traveler_segmentation.ipynb # K-Means clustering and persona evaluation
│   ├── 07_web_scraper.ipynb        # Destination description enrichment
│   └── 08_recommendation_engine.ipynb # Recommendation logic implementation
│
├── docs/                           # Project documentation & presentation guides
│   ├── project_report.md           # Comprehensive academic project report
│   └── demo_presentation_guide.md  # Slide deck outline and live demo script
│
└── test/                           # Automated test suites and verification scripts
```

---

## Installation and Setup

### 1. Prerequisites
* **Flutter SDK**: Version 3.19.0 or higher
* **Python**: Version 3.9 through 3.11
* **PostgreSQL**: PostgreSQL 14+ or a cloud Supabase database instance
* **API Credentials**:
  * Google Gemini API Key (`GEMINI_API_KEY`)
  * OpenWeatherMap API Key (`OPENWEATHER_API_KEY`)
  * OpenRouteService API Key (`ORS_API_KEY`)

---

### 2. Backend Configuration

```bash
# Navigate to backend directory
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install required packages
pip install -r requirements.txt

# Configure environment variables
# Create a .env file with appropriate database credentials and API keys:
# DATABASE_URL=postgresql://user:password@host:5432/dbname
# SECRET_KEY=your_secure_jwt_secret
# GEMINI_API_KEY=your_gemini_api_key
# OPENWEATHER_API_KEY=your_openweather_key
# ORS_API_KEY=your_openrouteservice_key

# Start the local development server
uvicorn main:app --reload --port 8000
```
Interactive API documentation will be available at `http://localhost:8000/docs` (Swagger UI).

---

### 3. Frontend Configuration

```bash
# Navigate to frontend directory
cd frontend

# Install Flutter dependencies
flutter pub get

# Run static analysis
flutter analyze

# Launch application on connected device or emulator
flutter run
```

---

## REST API Reference

| Method | Endpoint | Description | Authentication |
| :--- | :--- | :--- | :---: |
| `POST` | `/auth/register` | Register a new user account | Not Required |
| `POST` | `/auth/login` | Authenticate user credentials and return JWT | Not Required |
| `GET` | `/trips` | Retrieve all trips for the authenticated user | Required |
| `POST` | `/trips` | Create a new trip with target budget and dates | Required |
| `PUT` | `/trips/{id}` | Update existing trip parameters | Required |
| `DELETE` | `/trips/{id}` | Remove trip and cascade-delete associated expenses | Required |
| `GET` | `/expenses` | Retrieve all logged expenses | Required |
| `POST` | `/expenses` | Record a new categorized expense | Required |
| `POST` | `/api/ml/predict-cost` | Compute ML cost forecast using Random Forest Regressor | Not Required |
| `POST` | `/api/ml/predict-duration` | Compute recommended vacation duration | Not Required |
| `GET` | `/api/ml/recommendations` | Fetch personalized destination recommendations | Not Required |
| `POST` | `/api/ml/generate-itinerary` | Generate AI day-by-day itinerary via Google Gemini | Not Required |
| `GET` | `/api/ml/segmentation` | Calculate and return traveler persona clustering badge | Required |
| `GET` | `/api/analytics/dashboard` | Return aggregated spending analytics and ML benchmarks | Required |


