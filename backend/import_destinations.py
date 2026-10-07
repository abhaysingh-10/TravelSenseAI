import pandas as pd
from database import SessionLocal
from models import Destination

print("Connecting to PostgreSQL Database...")
db = SessionLocal()

print("Loading scraped Wikipedia data...")
df = pd.read_csv('../agent/dataset/data/scraped_destinations.csv')
df = df.dropna(subset=['name', 'description'])

print(f"Found {len(df)} valid destinations. Injecting into database...")

count = 0
for index, row in df.iterrows():
    # Check if it already exists to avoid duplicates
    existing = db.query(Destination).filter(Destination.name == row['name']).first()
    if not existing:
        new_dest = Destination(
            name=row['name'],
            description=row['description'],
            image_url=row['image_url'] if pd.notna(row['image_url']) else ""
        )
        db.add(new_dest)
        count += 1

db.commit()
db.close()
print(f"SUCCESS! {count} beautiful destinations permanently saved to PostgreSQL!")
