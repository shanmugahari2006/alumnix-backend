import sys
import os
import asyncio

# Add project root to python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import engine, Base
import app.models # Import to register models on Base

async def main():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("Database tables updated successfully!")

if __name__ == "__main__":
    asyncio.run(main())
