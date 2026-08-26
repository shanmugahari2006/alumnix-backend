import asyncio
from sqlalchemy import select
from app.database import async_session_maker
from app.models.user import User

async def dump_users():
    async with async_session_maker() as db:
        res = await db.execute(select(User))
        users = res.scalars().all()
        for u in users:
            print(f"Role: {u.role} | Name: {u.full_name} | Email: {u.email} | Phone: {u.phone_number} | Hashed PW: {u.hashed_password[:15]}...")

if __name__ == "__main__":
    asyncio.run(dump_users())
