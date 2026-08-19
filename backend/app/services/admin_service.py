import uuid
from typing import Optional, Tuple, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func
from sqlalchemy.future import select
from app.models.user import User, UserRole, Alumni
from app.models.job import JobListing
from app.models.event import Event
from app.models.donation import Donation
from fastapi import HTTPException, status

class AdminService:
    @staticmethod
    async def get_stats(db: AsyncSession) -> dict:
        """
        Gathers platform statistics by querying active user roles, pending alumni, and totals for jobs, events, and donations.
        """
        total_alumni_query = select(func.count()).select_from(User).where(User.role == UserRole.alumni)
        pending_alumni_query = select(func.count()).select_from(Alumni).where(Alumni.is_approved == False)
        total_students_query = select(func.count()).select_from(User).where(User.role == UserRole.student)
        total_jobs_query = select(func.count()).select_from(JobListing)
        total_donations_query = select(func.coalesce(func.sum(Donation.amount), 0.0)).where(Donation.status == "completed")
        total_events_query = select(func.count()).select_from(Event)
        
        # Execute queries asynchronously
        total_alumni_res = await db.execute(total_alumni_query)
        pending_alumni_res = await db.execute(pending_alumni_query)
        total_students_res = await db.execute(total_students_query)
        total_jobs_res = await db.execute(total_jobs_query)
        total_donations_res = await db.execute(total_donations_query)
        total_events_res = await db.execute(total_events_query)
        
        return {
            "total_alumni": total_alumni_res.scalar() or 0,
            "pending_alumni_approvals": pending_alumni_res.scalar() or 0,
            "total_students": total_students_res.scalar() or 0,
            "total_jobs_posted": total_jobs_res.scalar() or 0,
            "total_donations_amount": float(total_donations_res.scalar() or 0.0),
            "total_events": total_events_res.scalar() or 0
        }

    @staticmethod
    async def list_users(
        db: AsyncSession,
        role: Optional[UserRole] = None,
        status_filter: Optional[bool] = None,
        page: int = 1,
        limit: int = 10
    ) -> Tuple[int, List[User]]:
        """
        Retrieves users from the platform with optional filters and pagination.
        """
        query = select(User)
        if role is not None:
            query = query.where(User.role == role)
        if status_filter is not None:
            query = query.where(User.is_active == status_filter)
            
        # Execute total count query
        count_query = select(func.count()).select_from(query.subquery())
        count_res = await db.execute(count_query)
        total = count_res.scalar() or 0
        
        # Fetch paginated user results ordered by creation time descending
        offset = (page - 1) * limit
        query = query.order_by(User.created_at.desc()).offset(offset).limit(limit)
        results_res = await db.execute(query)
        users = results_res.scalars().all()
        
        return total, users

    @staticmethod
    async def update_user_status(
        db: AsyncSession,
        user_id: uuid.UUID,
        is_active: bool
    ) -> User:
        """
        Updates the active/blocked status of a specific user account.
        """
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalars().first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
            
        user.is_active = is_active
        await db.commit()
        await db.refresh(user)
        return user
