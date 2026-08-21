import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.user import User
from app.schemas.meeting import MeetingCreate, MeetingResponse, MeetingJoinResponse
from app.services.meeting_service import MeetingService
from app.dependencies import get_current_user
from app.utils.security import create_jitsi_token
from app.config import settings

router = APIRouter()

@router.post("", response_model=MeetingResponse, status_code=status.HTTP_201_CREATED)
async def create_meeting(
    payload: MeetingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new video conference session.
    """
    meeting = await MeetingService.create_meeting(db, payload, current_user)
    
    # Generate token for the host
    token = create_jitsi_token(
        room_name=meeting.room_name,
        user_id=str(current_user.id),
        user_name=current_user.full_name,
        user_email=current_user.email or ""
    )
    
    jitsi_url = f"https://{settings.JITSI_DOMAIN}/{meeting.room_name}?jwt={token}"
    
    return MeetingResponse(
        id=meeting.id,
        title=meeting.title,
        description=meeting.description,
        room_name=meeting.room_name,
        creator_id=meeting.creator_id,
        is_active=meeting.is_active,
        created_at=meeting.created_at,
        expires_at=meeting.expires_at,
        jitsi_url=jitsi_url,
        token=token
    )

@router.get("/active", response_model=List[MeetingResponse])
async def list_active_meetings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List all active video conferencing sessions.
    """
    meetings = await MeetingService.get_active_meetings(db)
    response_list = []
    
    for meeting in meetings:
        token = create_jitsi_token(
            room_name=meeting.room_name,
            user_id=str(current_user.id),
            user_name=current_user.full_name,
            user_email=current_user.email or ""
        )
        jitsi_url = f"https://{settings.JITSI_DOMAIN}/{meeting.room_name}?jwt={token}"
        
        response_list.append(
            MeetingResponse(
                id=meeting.id,
                title=meeting.title,
                description=meeting.description,
                room_name=meeting.room_name,
                creator_id=meeting.creator_id,
                is_active=meeting.is_active,
                created_at=meeting.created_at,
                expires_at=meeting.expires_at,
                jitsi_url=jitsi_url,
                token=token
            )
        )
    return response_list

@router.post("/{room_name}/join", response_model=MeetingJoinResponse)
async def join_meeting(
    room_name: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Join an active video conference session and get a signed Jitsi JWT token.
    """
    meeting = await MeetingService.get_meeting_by_room(db, room_name)
    token = create_jitsi_token(
        room_name=meeting.room_name,
        user_id=str(current_user.id),
        user_name=current_user.full_name,
        user_email=current_user.email or ""
    )
    jitsi_url = f"https://{settings.JITSI_DOMAIN}/{meeting.room_name}?jwt={token}"
    
    return MeetingJoinResponse(
        room_name=meeting.room_name,
        token=token,
        jitsi_url=jitsi_url
    )

@router.delete("/{room_name}", status_code=status.HTTP_204_NO_CONTENT)
async def end_meeting(
    room_name: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Deactivate/end a video conference session. Only the creator can end it.
    """
    await MeetingService.end_meeting(db, room_name, current_user.id)
