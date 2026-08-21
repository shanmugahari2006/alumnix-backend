import uuid
from typing import List, Optional
from fastapi import HTTPException
from sqlalchemy import func, String, or_, and_, select
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User, Alumni
from app.schemas.alumni import AlumniProfileUpdate

class AlumniService:
    @staticmethod
    async def search_alumni(
        db: AsyncSession,
        search: Optional[str] = None,
        branch: Optional[str] = None,
        batch: Optional[int] = None,
        location: Optional[str] = None,
        skills: Optional[List[str]] = None,
        page: int = 1,
        limit: int = 10
    ) -> tuple[int, List[Alumni]]:
        """
        Queries and filters approved alumni profiles in the database with offset pagination.
        """
        # Base count and query
        count_query = select(func.count(Alumni.id)).join(User).where(Alumni.is_approved == True, User.is_active == True)
        query = select(Alumni).join(User).options(joinedload(Alumni.user)).where(Alumni.is_approved == True, User.is_active == True)
        
        # Build filter predicates
        filters = []
        if search:
            filters.append(or_(User.full_name.ilike(f"%{search}%"), Alumni.company.ilike(f"%{search}%")))
        if branch:
            filters.append(Alumni.branch.ilike(f"%{branch}%"))
        if batch:
            filters.append(Alumni.graduation_year == batch)
        if location:
            filters.append(Alumni.location.ilike(f"%{location}%"))
        if skills:
            for skill in skills:
                filters.append(Alumni.skills.cast(String).ilike(f"%{skill}%"))
                
        if filters:
            count_query = count_query.where(and_(*filters))
            query = query.where(and_(*filters))
            
        # Fetch counts
        total_result = await db.execute(count_query)
        total = total_result.scalar() or 0
        
        # Paginate results
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)
        result = await db.execute(query)
        alumni_list = result.scalars().all()
        
        return total, alumni_list

    @staticmethod
    async def update_profile(
        db: AsyncSession,
        user_id: uuid.UUID,
        update_data: AlumniProfileUpdate
    ) -> Alumni:
        """
        Updates profile attributes for a logged-in alumni user.
        """
        result = await db.execute(select(Alumni).where(Alumni.id == user_id))
        alumni = result.scalars().first()
        if not alumni:
            raise HTTPException(status_code=404, detail="Alumni profile not found")
            
        data = update_data.model_dump(exclude_unset=True)
        for key, value in data.items():
            setattr(alumni, key, value)
            
        await db.commit()
        await db.refresh(alumni)
        return alumni

    @staticmethod
    async def approve_alumni(
        db: AsyncSession,
        alumni_id: uuid.UUID
    ) -> Alumni:
        """
        Approves an alumni user and triggers a mock notification.
        """
        result = await db.execute(select(Alumni).where(Alumni.id == alumni_id).join(User).options(joinedload(Alumni.user)))
        alumni = result.scalars().first()
        if not alumni:
            raise HTTPException(status_code=404, detail="Alumni profile not found")
            
        alumni.is_approved = True
        await db.commit()
        await db.refresh(alumni)
        
        # Trigger Mock Notification
        print(f"[MOCK NOTIFICATION] Triggered: Alumni account {alumni.id} (Email: {alumni.user.email}) has been approved!")
        
        return alumni
