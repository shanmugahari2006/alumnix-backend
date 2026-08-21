import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.user import User
from app.models.event import EventRegistration
from app.schemas.event import EventCreate, EventResponse, EventRegistrationResponse, AttendeeDetail
from app.services.event_service import EventService
from app.dependencies import get_current_user, require_role

router = APIRouter()

@router.post("", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
async def create_event(
    payload: EventCreate,
    current_user: User = Depends(require_role(["faculty", "admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new event listing (Faculty and Admin only).
    """
    return await EventService.create_event(db, payload, current_user.id)

@router.get("", response_model=List[EventResponse])
async def list_events(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all events ordered by date descending.
    """
    events = await EventService.list_events(db)
    
    # Query registrations for the current user
    reg_res = await db.execute(
        select(EventRegistration.event_id).where(EventRegistration.user_id == current_user.id)
    )
    registered_ids = set(reg_res.scalars().all())
    
    # Map the events
    return [
        EventResponse(
            id=e.id,
            title=e.title,
            description=e.description,
            date=e.date,
            location=e.location,
            creator_id=e.creator_id,
            created_at=e.created_at,
            is_registered=(e.id in registered_ids)
        )
        for e in events
    ]

@router.post("/{event_id}/register", response_model=EventRegistrationResponse, status_code=status.HTTP_201_CREATED)
async def register_for_event(
    event_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Register the current logged-in user to attend an event.
    """
    return await EventService.register_for_event(db, event_id, current_user.id)

@router.get("/{event_id}/attendees", response_model=List[AttendeeDetail])
async def get_event_attendees(
    event_id: uuid.UUID,
    current_user: User = Depends(require_role(["faculty", "admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    List all users registered to attend a specific event (Faculty and Admin only).
    """
    registrations = await EventService.get_attendees(db, event_id)
    return [
        AttendeeDetail(
            id=reg.user.id,
            full_name=reg.user.full_name,
            email=reg.user.email,
            role=reg.user.role
        )
        for reg in registrations
    ]
