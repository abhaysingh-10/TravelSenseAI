# TravelSense AI — Comprehensive Project Report

## 1. Executive Summary & Problem Statement
Modern travel planning is fragmented across separate applications for budgeting, itinerary planning, destination discovery, and expense tracking. Travelers often struggle with realistic cost forecasting, suboptimal budget allocation, and time-consuming manual itinerary creation.

**TravelSense AI** solves this by providing a unified, AI-native mobile platform that combines:
1. **Predictive Machine Learning**: Random Forest regression models to estimate total travel expenditure and recommended trip durations.
2. **Behavioral Segmentation**: K-Means clustering to classify travelers into distinct behavioral personas (e.g., Luxury, Backpacker, Standard, Vacationer).
3. **Curated Recommendations**: Content-based filtering matching traveler styles with 31 verified Indian destinations.
4. **Generative AI Itineraries**: Google Gemini LLM integration generating personalized morning, afternoon, and evening daily itineraries.
5. **Real-Time Analytics & ML Benchmarking**: Interactive spending charts and budget efficiency scoring comparing user spending against machine learning baselines.

---

## 2. System Architecture

The solution uses a three-tier architecture:

```
┌────────────────────────────────────────────────────────┐
│                   Flutter Mobile App                   │
│   (Riverpod State Management, Material 3, FL Chart)    │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST (JWT Auth)
┌───────────────────────────▼────────────────────────────┐
│                  FastAPI Backend Server                │
│    (Deployed on Render, Python 3.9+, Async Uvicorn)    │
├───────────────────────────┬────────────────────────────┤
│  • Auth & User Management │  • ML Prediction Engine    │
│  • Trip & Expense CRUD    │  • Gemini Generative AI    │
│  • Analytics Aggregation  │  • External API Services   │
└─────────────┬───────────────────────────┬──────────────┘
              │                           │
┌─────────────▼─────────────┐   ┌─────────▼──────────────┐
│  Supabase PostgreSQL DB   │   │     External APIs      │
│  (Users, Trips, Expenses, │   │ • Google Gemini LLM    │
│   Destinations)           │   │ • OpenWeatherMap       │
│                           │   │ • OpenRouteService     │
└───────────────────────────┘   └────────────────────────┘
```

---

## 3. Core Modules & Implementation

### 3.1 Authentication & Security
* **JWT (JSON Web Tokens)**: Secure token-based session handling with cryptographic signing.
* **Password Hashing**: Bcrypt encryption with salted passwords before database storage.
* **Client-Side Secure Storage**: Encrypted token persistence via `flutter_secure_storage`.

### 3.2 Trip & Expense Management
* **Hierarchical Data Model**: Trips maintain metadata (destination, start/end dates, budget) and have one-to-many relationships with categorized expenses (Food, Accommodation, Transport, Sightseeing, Shopping).
* **Live Weather Integration**: Automatically queries OpenWeatherMap for the destination's current temperature and weather conditions upon trip creation.
* **Realtime Budget Tracking**: Dynamic progress indicators alert users when expenditures approach or exceed set limits.

### 3.3 Predictive ML Engine
* **Cost Prediction**: Takes destination, number of travelers, transport mode (Flight/Train/Bus), hotel class (Budget/Standard/Luxury), and season to output an expected total cost in INR.
* **Duration Prediction**: Analyzes budget constraints, destination distance, and traveler persona to estimate optimal vacation duration.
* **Routing Distance**: Uses OpenRouteService (ORS) to calculate true highway driving distance between source and destination cities.

### 3.4 AI Destination Recommendations & Carousel
* **31 Curated Indian Destinations**: Pre-processed and enriched with Wikipedia descriptions, estimated costs, and historical sight keywords.
* **Offline Asset Pipeline**: All 31 destinations feature bundled local high-resolution assets (`assets/images/destinations/`) with automatic fallback to remote images.
* **Home Screen Carousel**: Auto-rotating carousel highlighting top 3 matched picks with instant navigation to detailed itinerary views.

### 3.5 Generative AI Daily Itinerary
* **Multi-Day Itinerary Generation**: Uses Google's Gemini Large Language Model (LLM) to dynamically structure day-by-day itineraries.
* **Day Parts**: Morning (primary sights & breakfast), Afternoon (cultural attractions & regional cuisine), Evening (sunset viewpoints & authentic dining).
* **In-Memory Caching**: Implemented in Riverpod to store generated itineraries for the entire app session, eliminating repeated network calls and providing 0.0-second instant loading.
* **Resilient Fallback**: Automatic failover to rich, structured curated itineraries if network is slow or offline.

### 3.6 Analytics Dashboard & ML Budget Efficiency
* **Interactive FL Charts**: Visualizes cumulative spending trends over time and categorized expense distribution pie charts.
* **AI Budget Efficiency Metric**: Calculates user spending relative to ML benchmark predictions:
  $$\text{Budget Efficiency (\%)} = \left(1 - \frac{\text{Actual Cost} - \text{Predicted Cost}}{\text{Predicted Cost}}\right) \times 100$$
* Displays net savings, spending status badges ("Smart Spender" vs. "Over Budget"), and destination breakdown tables.

---

## 4. Machine Learning Models & Evaluation

The machine learning pipeline was trained across 8 comprehensive Jupyter notebooks using Scikit-Learn:

### 4.1 Cost Prediction Model
* **Model Type**: Random Forest Regressor (`cost_prediction_rf.pkl`)
* **Evaluation Metrics**:
  * **Mean Absolute Error (MAE)**: $\approx$ ₹6,103
  * **Coefficient of Determination ($R^2$)**: **89.9%**
* **Key Features**: Distance (km), Travel Duration (hrs), Travelers Count, Transport Mode, Hotel Tier, Season, Destination Zone.

### 4.2 Duration Prediction Model
* **Model Type**: Random Forest Regressor (`duration_prediction_rf.pkl`)
* **Evaluation Metrics**:
  * **Mean Absolute Error (MAE)**: **0.45 Days** (less than half a day error)
  * **Coefficient of Determination ($R^2$)**: **74.3%**
* **Key Features**: Total Cost, Distance, Travelers Count, Hotel Class, Season.

### 4.3 Traveler Segmentation (Clustering)
* **Model Type**: K-Means Clustering ($k=4$)
* **Identified Clusters**:
  1. *Luxury Travelers*: High budget allocation, flight travel, luxury resort preference.
  2. *Frequent Backpackers*: Low daily spend, bus/train travel, high frequency.
  3. *Standard Travelers*: Mid-tier budget, family exploration, balanced pacing.
  4. *Occasional Vacationers*: Seasonal trips, moderate spending, leisure focus.
* **Profile Integration**: Profiles dynamically compute and display the user's cluster badge.

---

## 5. Database Schema

```sql
-- Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trips Table
CREATE TABLE trips (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    destination VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget DOUBLE PRECISION NOT NULL,
    image_url VARCHAR(500),
    weather_temp DOUBLE PRECISION,
    weather_condition VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Expenses Table
CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER REFERENCES trips(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    category VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Destinations Table
CREATE TABLE destinations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 6. Conclusion
TravelSense AI delivers a complete, cohesive end-to-end software solution bridging mobile user experience with cloud infrastructure and applied artificial intelligence. By unifying predictive regression, unsupervised clustering, generative LLMs, and real-time analytics into a single responsive Flutter client, the application demonstrates production-ready engineering suitable for academic evaluation and industry deployment.
