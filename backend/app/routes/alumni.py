import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.user import User
from app.schemas.alumni import AlumniProfileUpdate, AlumniPaginatedResponse, AlumniSearchResult
from app.schemas.auth import AlumniUserResponse, UserResponse, AlumniProfileResponse
from app.services.alumni_service import AlumniService
from app.dependencies import get_current_user, require_role

router = APIRouter()

@router.get("", response_model=AlumniPaginatedResponse)
async def search_alumni(
    search: Optional[str] = None,
    branch: Optional[str] = None,
    batch: Optional[int] = None,
    location: Optional[str] = None,
    skills: Optional[List[str]] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    Search approved alumni profiles with directory pagination.
    """
    total, results = await AlumniService.search_alumni(
        db, search=search, branch=branch, batch=batch, location=location, skills=skills, page=page, limit=limit
    )
    
    # Map raw model fields joined with users into search results
    mapped_results = []
    for item in results:
        mapped_results.append(AlumniSearchResult(
            id=item.id,
            full_name=item.user.full_name,
            email=item.user.email,
            company=item.company,
            designation=item.designation,
            graduation_year=item.graduation_year,
            branch=item.branch,
            location=item.location,
            linkedin_url=item.linkedin_url,
            skills=item.skills
        ))
        
    return AlumniPaginatedResponse(
        total=total,
        page=page,
        limit=limit,
        results=mapped_results
    )

@router.put("/profile", response_model=AlumniUserResponse)
async def update_profile(
    payload: AlumniProfileUpdate,
    current_user: User = Depends(require_role(["alumni"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Allows an authenticated alumni to update their directory profile attributes.
    """
    updated_alumni = await AlumniService.update_profile(db, current_user.id, payload)
    return AlumniUserResponse(
        user=UserResponse.model_validate(current_user),
        alumni=AlumniProfileResponse.model_validate(updated_alumni)
    )

@router.patch("/{alumni_id}/approve", response_model=AlumniUserResponse)
async def approve_alumni(
    alumni_id: uuid.UUID,
    admin_user: User = Depends(require_role(["admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Allows admins to activate and approve alumni registrations. Triggers mock verification warnings/emails.
    """
    approved_alumni = await AlumniService.approve_alumni(db, alumni_id)
    return AlumniUserResponse(
        user=UserResponse.model_validate(approved_alumni.user),
        alumni=AlumniProfileResponse.model_validate(approved_alumni)
    )
