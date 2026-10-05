import os
import httpx

WEATHER_API_KEY = os.getenv("OPENWEATHER_API_KEY")
ROUTE_API_KEY = os.getenv("OPENROUTE_API_KEY")

async def get_weather_for_city(city_name: str) -> float:
    """
    Fetches the current temperature for a given city in Celsius.
    Returns 25.0 as a default fallback if the API fails.
    """
    if not WEATHER_API_KEY:
        return 25.0

    url = f"https://api.openweathermap.org/data/2.5/weather?q={city_name}&appid={WEATHER_API_KEY}&units=metric"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, timeout=5.0)
            if response.status_code == 200:
                data = response.json()
                return data['main']['temp']
        except Exception as e:
            print(f"Weather API Error: {e}")
            
    return 25.0

async def geocode_city(city_name: str):
    """
    Geocodes a city name to (longitude, latitude) using OpenRouteService.
    Returns None if fails.
    """
    if not ROUTE_API_KEY:
        return None

    url = f"https://api.openrouteservice.org/geocode/search?api_key={ROUTE_API_KEY}&text={city_name}"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, timeout=5.0)
            if response.status_code == 200:
                data = response.json()
                if data['features']:
                    # ORS returns [lon, lat]
                    coords = data['features'][0]['geometry']['coordinates']
                    return coords[0], coords[1]
        except Exception as e:
            print(f"Geocoding Error: {e}")
            
    return None

async def get_distance_between_cities(city1: str, city2: str) -> float:
    """
    Calculates driving distance in kilometers between two cities using OpenRouteService.
    Returns 0.0 if it fails.
    """
    if not ROUTE_API_KEY:
        return 0.0

    coords1 = await geocode_city(city1)
    coords2 = await geocode_city(city2)

    if not coords1 or not coords2:
        return 0.0

    # ORS directions API expects coordinates as lon,lat
    url = f"https://api.openrouteservice.org/v2/directions/driving-car?api_key={ROUTE_API_KEY}&start={coords1[0]},{coords1[1]}&end={coords2[0]},{coords2[1]}"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url, timeout=5.0)
            if response.status_code == 200:
                data = response.json()
                # distance is in meters, convert to km
                distance_meters = data['features'][0]['properties']['summary']['distance']
                return round(distance_meters / 1000.0, 2)
        except Exception as e:
            print(f"Routing Error: {e}")
            
    return 0.0

async def get_image_for_city(city_name: str) -> str:
    """
    Fetches a scenic image URL for the given city using the Wikipedia API.
    Falls back to a default Unsplash image if none is found or if it fails.
    """
    import urllib.parse
    # Append 'tourism' to force Wikipedia to return scenic landmarks instead of politicians/maps
    search_query = urllib.parse.quote(f"{city_name} tourism")
    url = f"https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch={search_query}&prop=pageimages&format=json&pithumbsize=1000&gsrlimit=5"
    headers = {"User-Agent": "TravelSenseAI/1.0 (https://github.com/abhaysingh-10/TravelSenseAI)"}
    
    async with httpx.AsyncClient(follow_redirects=True, headers=headers) as client:
        try:
            response = await client.get(url, timeout=5.0)
            if response.status_code == 200:
                data = response.json()
                pages = data.get("query", {}).get("pages", {})
                for p_id, p_info in pages.items():
                    if "thumbnail" in p_info:
                        return p_info["thumbnail"]["source"]
        except Exception as e:
            print(f"Image Fetch Error: {e}")
            
    return "https://raw.githubusercontent.com/abhaysingh-10/TravelSenseAI/main/frontend/assets/icon/app_icon.jpg"
