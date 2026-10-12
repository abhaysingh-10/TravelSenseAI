import os
import sys
from dotenv import load_dotenv

load_dotenv('backend/.env')
sys.path.append('backend')
from database import SessionLocal
from models import Destination

HIGH_RES_IMAGES = {
    "Chikmagalur": "https://images.unsplash.com/photo-1596176530529-78163a4f7af2?auto=format&fit=crop&w=1200&q=80",
    "Agra": "https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=1200&q=80",
    "Alleppey": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=80",
    "Bandipur": "https://images.unsplash.com/photo-1575550959106-5a7defe28b56?auto=format&fit=crop&w=1200&q=80",
    "Goa": "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=1200&q=80",
    "Jaipur": "https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=1200&q=80",
    "Munnar": "https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?auto=format&fit=crop&w=1200&q=80",
    "Manali": "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?auto=format&fit=crop&w=1200&q=80",
    "Ooty": "https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?auto=format&fit=crop&w=1200&q=80",
    "Varanasi": "https://images.unsplash.com/photo-1561361513-2d000a50f0dc?auto=format&fit=crop&w=1200&q=80",
    "Gokarna": "https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?auto=format&fit=crop&w=1200&q=80",
    "Pondicherry": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80",
    "Puri": "https://images.unsplash.com/photo-1629814249584-c4d53b017d2b?auto=format&fit=crop&w=1200&q=80",
    "Amritsar": "https://images.unsplash.com/photo-1588096344356-9a572c672e35?auto=format&fit=crop&w=1200&q=80",
    "Srinagar": "https://images.unsplash.com/photo-1598091383021-15ddea10925d?auto=format&fit=crop&w=1200&q=80",
    "Spiti Valley": "https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&w=1200&q=80",
    "Kodaikanal": "https://images.unsplash.com/photo-1596895111956-bf1cf0599ce5?auto=format&fit=crop&w=1200&q=80",
    "Mussoorie": "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=1200&q=80",
    "Shillong": "https://images.unsplash.com/photo-1596701062351-8c2c14d1fdd1?auto=format&fit=crop&w=1200&q=80",
    "Havelock Island": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80",
    "Rameshwaram": "https://images.unsplash.com/photo-1616489953149-8c9f521b474f?auto=format&fit=crop&w=1200&q=80",
    "Mysore": "https://images.unsplash.com/photo-1600100397608-f010f4439c71?auto=format&fit=crop&w=1200&q=80",
    "Madurai": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80",
    "Kaziranga": "https://images.unsplash.com/photo-1564349683136-77e08dba1ef7?auto=format&fit=crop&w=1200&q=80",
    "Pushkar": "https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=1200&q=80",
    "Kovalam": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80",
    "Bodh Gaya": "https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80",
    "Khajuraho": "https://images.unsplash.com/photo-1608958435020-e8a7109ba809?auto=format&fit=crop&w=1200&q=80",
    "Tirupati": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80",
    "Wayanad": "https://images.unsplash.com/photo-1609137144813-7d9921338f24?auto=format&fit=crop&w=1200&q=80",
    "Gangtok": "https://images.unsplash.com/photo-1617854818583-09e7f077a156?auto=format&fit=crop&w=1200&q=80",
}

def update_images():
    print("Connecting to Supabase PostgreSQL database...")
    db = SessionLocal()
    updated_count = 0
    
    for name, img_url in HIGH_RES_IMAGES.items():
        dest = db.query(Destination).filter(Destination.name == name).first()
        if dest:
            dest.image_url = img_url
            updated_count += 1
            print(f"Updated {name} with high-res image.")
        else:
            print(f"Destination not found: {name}")
            
    db.commit()
    db.close()
    print(f"SUCCESS: Updated {updated_count} destinations with crystal-clear HD imagery!")

if __name__ == "__main__":
    update_images()
