import asyncio
from sqlalchemy import select
from app.database import async_session_maker
from app.models.faculty import Faculty
from app.models.alumni import Alumni
from sqlalchemy.orm import selectinload

async def test_pending():
    async with async_session_maker() as db:
        faculty_res = await db.execute(select(Faculty).where(Faculty.is_approved == False).options(selectinload(Faculty.user)))
        pending_faculty = faculty_res.scalars().all()
        print(f"Pending Faculty: {len(pending_faculty)}")
        
        alumni_res = await db.execute(select(Alumni).where(Alumni.is_approved == False).options(selectinload(Alumni.user)))
        pending_alumni = alumni_res.scalars().all()
        print(f"Pending Alumni: {len(pending_alumni)}")

if __name__ == "__main__":
    asyncio.run(test_pending())
