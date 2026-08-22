import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.user import User, UserRole
from app.dependencies import require_role
from app.schemas.admin import AdminStatsResponse, AdminUsersPaginatedResponse, UserStatusUpdate
from app.schemas.auth import UserResponse, AlumniUserResponse
from app.schemas.faculty import FacultyResponse
from app.services.admin_service import AdminService
from sqlalchemy.orm import selectinload
from sqlalchemy import select
from app.models.faculty import Faculty
from app.models.alumni import Alumni
from typing import List
# Restrict all routes in this router to admin role.
router = APIRouter(dependencies=[Depends(require_role(["admin"]))])

@router.get("/stats", response_model=AdminStatsResponse)
async def get_stats(db: AsyncSession = Depends(get_db)):
    """
    Returns aggregated platform statistics for the Admin Dashboard.
    """
    stats = await AdminService.get_stats(db)
    return stats

@router.get("/users", response_model=AdminUsersPaginatedResponse)
async def list_users(
    role: Optional[UserRole] = Query(None, description="Filter users by role"),
    status: Optional[bool] = Query(None, description="Filter users by active/blocked status"),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns a paginated and filterable list of all registered platform users.
    """
    total, users = await AdminService.list_users(
        db=db,
        role=role,
        status_filter=status,
        page=page,
        limit=limit
    )
    # Map raw user SQLAlchemy objects to Pydantic model response
    results = [UserResponse.model_validate(u) for u in users]
    return AdminUsersPaginatedResponse(
        total=total,
        page=page,
        limit=limit,
        results=results
    )

@router.patch("/users/{user_id}/status", response_model=UserResponse)
async def update_user_status(
    user_id: uuid.UUID,
    payload: UserStatusUpdate,
    db: AsyncSession = Depends(get_db)
):
    """
    Activates or blocks specific user accounts by toggling is_active status.
    """
    user = await AdminService.update_user_status(
        db=db,
        user_id=user_id,
        is_active=payload.is_active
    )
    return UserResponse.model_validate(user)

@router.get("/pending-faculty", response_model=List[FacultyResponse])
async def list_pending_faculty(db: AsyncSession = Depends(get_db)):
    """
    Returns a list of faculty registrations pending admin approval.
    """
    res = await db.execute(
        select(Faculty)
        .where(Faculty.is_approved == False)
        .options(selectinload(Faculty.user))
    )
    faculty_list = res.scalars().all()
    return [FacultyResponse.model_validate(f) for f in faculty_list]

@router.get("/pending-alumni", response_model=List[AlumniUserResponse])
async def list_pending_alumni(db: AsyncSession = Depends(get_db)):
    """
    Returns a list of alumni registrations pending admin approval.
    """
    res = await db.execute(
        select(Alumni)
        .where(Alumni.is_approved == False)
        .options(selectinload(Alumni.user))
    )
    alumni_list = res.scalars().all()
    return [AlumniUserResponse(user=UserResponse.model_validate(a.user), alumni=a) for a in alumni_list]
