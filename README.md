# ✈️ TravelSense AI
### *Smart Travel Planning & Expense Management Powered by Machine Learning & Generative AI*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Supabase-336791?logo=postgresql)](https://supabase.com)
[![Scikit-Learn](https://img.shields.io/badge/ML-Scikit--Learn-F7931E?logo=scikitlearn)](https://scikit-learn.org)
[![Gemini](https://img.shields.io/badge/AI-Google_Gemini-4285F4?logo=google)](https://ai.google.dev)

---

## 📖 Overview

**TravelSense AI** is a full-stack, AI-driven mobile travel companion designed to modernize trip planning, cost estimation, and expense management. By combining **predictive machine learning models**, **unsupervised clustering**, and **Google Gemini Generative AI**, TravelSense AI provides travelers with real-time budget forecasting, personalized destination curation, custom multi-day itineraries, and deep spending analytics.

---

## ✨ Key Features

### 1. 🤖 Predictive ML Engine (Cost & Duration)
* **Random Forest Regressors** trained on travel data predict overall trip expenditure based on distance, group size, hotel tier, season, and travel style.
* Automatically predicts optimal trip duration in days tailored to destination distance and budget constraints.
* Dynamic distance calculation using **OpenRouteService / OSRM**.

### 2. 🗺️ Intelligent Destination Recommendations
* Content-based recommendation filtering for **31 curated Indian destinations**.
* Enriched with scraped Wikipedia descriptions and verified multi-tier offline local assets (`assets/images/destinations/`).
* Instant fallback handling ensures images and destination details load with zero latency even without an active internet connection.

### 3. 📝 Dynamic Generative Itineraries (Google Gemini)
* Personalized day-by-day schedules generated on-demand matching the traveler's style (Budget, Standard, Luxury).
* Structured breakdown for **Morning**, **Afternoon**, and **Evening** highlights, authentic local cuisine recommendations, and scenic viewpoints.
* In-memory caching for **instantaneous (0.0s)** re-opening and resilient offline curated fallback.

### 4. 📊 Analytics Dashboard & ML Budget Efficiency
* Visual spending trends and category breakdowns powered by interactive **FL Chart** widgets.
* **AI Budget Efficiency Benchmark**: Compares actual trip expenditures against ML regression baselines to score spending efficiency and calculate net savings.
* Pull-to-refresh data synchronization across trips, expenses, and analytics.

### 5. 🏷️ Traveler Segmentation & Profiling
* **K-Means Clustering** categorizes travelers into distinct personas (e.g., *Budget Explorer*, *Luxury Vacationer*, *Family Planner*).
* Live traveler segment badge displayed prominently on the user profile.

### 6. 💼 Robust Trip & Expense Management
* Complete CRUD operations for trips and categorized expenses (Food, Accommodation, Transport, Sightseeing, Shopping).
* Real-time budget progress bar, remaining allowance calculations, and live weather conditions via **OpenWeatherMap**.

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph Client ["Flutter Mobile Client"]
        UI["Riverpod UI Layer\n(Screens, Widgets, Charts)"]
        Cache["In-Memory State & Caching"]
        Storage["Flutter Secure Storage (JWT)"]
    end

    subgraph CloudAPI ["FastAPI Backend (Render)"]
        Router["FastAPI Application"]
        Auth["JWT & Bcrypt Security"]
        MLService["ML Inference Engine"]
        ExtService["Weather & Distance Services"]
    end

    subgraph DataML ["Data, ML & AI Layer"]
        DB[(Supabase PostgreSQL)]
        RF_Cost["Cost Model (.pkl)"]
        RF_Duration["Duration Model (.pkl)"]
        KMeans["Clustering Model"]
        Gemini["Google Gemini LLM"]
    end

    UI -->|REST API over HTTPS| Router
    Router --> Auth
    Router --> MLService
    Router --> ExtService
    Router --> DB
    MLService --> RF_Cost
    MLService --> RF_Duration
    MLService --> KMeans
    MLService --> Gemini
```

---

## 🛠️ Technology Stack

| Component | Technology / Library | Purpose |
| :--- | :--- | :--- |
| **Mobile App** | Flutter 3.x, Dart | Cross-platform iOS & Android mobile interface |
| **State Management** | Riverpod 2.x | Reactive dependency injection and provider caching |
| **Charts & Visuals** | `fl_chart`, `google_fonts` | Spending analytics and modern UI design system |
| **Backend Framework** | FastAPI (Python 3.9+) | Asynchronous, high-performance RESTful API microservice |
| **Cloud Database** | PostgreSQL via Supabase | Relational persistence for users, trips, and expenses |
| **ORM & Migrations** | SQLAlchemy, Alembic | Database object-relational mapping and schema versioning |
| **Machine Learning** | Scikit-learn, Pandas, NumPy | Regression prediction models & K-Means clustering |
| **Generative AI** | Google Gemini Generative AI | Dynamic personalized day-by-day itineraries |
| **External APIs** | OpenWeatherMap, OpenRouteService | Real-time weather forecasts and distance routing |
| **Hosting** | Render (API), Supabase (DB) | Continuous deployment cloud infrastructure |

---

## 📁 Project Structure

```
TravelSenseAI/
├── backend/                        # FastAPI REST API Backend
│   ├── main.py                     # Main application entrypoint & API routers
│   ├── models.py                   # SQLAlchemy database entity models
│   ├── schemas.py                  # Pydantic validation schemas
│   ├── database.py                 # PostgreSQL connection setup
│   ├── auth.py                     # JWT token handling & password hashing
│   ├── ml_service.py               # ML inference, recommendations & Gemini LLM
│   ├── services.py                 # External APIs (Weather, Distance, Images)
│   ├── ml_data/                    # Trained .pkl models & trip datasets
│   └── requirements.txt            # Python dependencies
│
├── frontend/                       # Flutter Cross-Platform Mobile Client
│   ├── lib/
│   │   ├── main.dart               # Flutter application entrypoint
│   │   ├── models/                 # Data models (Trip, Expense, Destination, User)
│   │   ├── providers/              # Riverpod state notifiers & cached providers
│   │   ├── screens/                # 12+ application screens (Home, Predictor, Dashboard, etc.)
│   │   ├── services/               # API service & secure storage
│   │   ├── theme/                  # Global theme tokens, typography, and colors
│   │   └── widgets/                # Reusable UI widgets & AI Picks Carousel
│   └── assets/images/destinations/ # 31 high-resolution offline destination assets
│
├── notebooks/                      # Jupyter / Google Colab ML Training Pipeline
│   ├── 01_data_cleaning.ipynb      # Missing value treatment & outlier handling
│   ├── 02_eda.ipynb                # Exploratory data analysis & distributions
│   ├── 03_feature_engineering.ipynb# Feature scaling, encoding, and derived metrics
│   ├── 04_model_training.ipynb     # Cost prediction model training & evaluation
│   ├── 05_duration_prediction.ipynb# Duration prediction model training
│   ├── 06_traveler_segmentation.ipynb # K-Means clustering & persona labeling
│   ├── 07_web_scraper.ipynb        # Destination descriptions & asset scraping
│   └── 08_recommendation_engine.ipynb # Content-based filtering logic
│
└── test/                           # Automated & manual integration test suites
```

---

## 🚀 Getting Started

### 1. Prerequisites
* **Flutter SDK**: `^3.19.0` or higher
* **Python**: `3.9` through `3.11`
* **PostgreSQL** or free-tier Supabase account
* Free API keys for:
  * Google Gemini API (`GEMINI_API_KEY`)
  * OpenWeatherMap (`OPENWEATHER_API_KEY`)
  * OpenRouteService (`ORS_API_KEY`)

---

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables (.env)
# Create a .env file matching .env.example with your database and API keys:
# DATABASE_URL=postgresql://user:pass@host:5432/dbname
# SECRET_KEY=your_jwt_secret_key
# GEMINI_API_KEY=your_gemini_key
# OPENWEATHER_API_KEY=your_weather_key
# ORS_API_KEY=your_ors_key

# Run local development server
uvicorn main:app --reload --port 8000
```
API Documentation will be live at: `http://localhost:8000/docs` (Swagger UI).

---

### 3. Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Install Flutter dependencies
flutter pub get

# Verify environment setup
flutter analyze

# Run on connected device, simulator, or emulator
flutter run
```

---

## 📡 REST API Reference

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `POST` | `/auth/register` | Register a new user account | No |
| `POST` | `/auth/login` | Authenticate user & issue JWT bearer token | No |
| `GET` | `/trips` | Retrieve all trips for authenticated user | Yes |
| `POST` | `/trips` | Create a new trip plan with budget | Yes |
| `PUT` | `/trips/{id}` | Update existing trip details | Yes |
| `DELETE` | `/trips/{id}` | Delete a trip and associated expenses | Yes |
| `GET` | `/expenses` | List all logged expenses | Yes |
| `POST` | `/expenses` | Log a new categorized expense | Yes |
| `POST` | `/api/ml/predict-cost` | Predict trip cost using Random Forest ML | No |
| `POST` | `/api/ml/predict-duration` | Predict optimal duration using Random Forest ML | No |
| `GET` | `/api/ml/recommendations` | Get content-filtered curated destination picks | No |
| `POST` | `/api/ml/generate-itinerary` | Generate AI day-by-day itinerary with Gemini | No |
| `GET` | `/api/ml/segmentation` | Calculate live traveler clustering segment | Yes |
| `GET` | `/api/analytics/dashboard` | Aggregated analytics & ML budget benchmarks | Yes |

---

## 👥 Authors & Acknowledgments

* **Lead Developer & ML Engineer**: Abhay Singh
* Built with ❤️ for seamless, intelligent, and budget-conscious travel exploration.
