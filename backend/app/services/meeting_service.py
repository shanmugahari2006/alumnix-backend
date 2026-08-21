import uuid
import datetime
from typing import List
from fastapi import HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.meeting import MeetingSession
from app.models.user import User
from app.schemas.meeting import MeetingCreate

class MeetingService:
    @staticmethod
    async def create_meeting(db: AsyncSession, meeting_data: MeetingCreate, creator: User) -> MeetingSession:
        """
        Creates a new meeting session and saves it in the database.
        """
        # Generate a secure room name to avoid collision
        room_name = f"alumni-{uuid.uuid4().hex}"
        
        expires_at = None
        if meeting_data.expires_in_minutes:
            expires_at = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=meeting_data.expires_in_minutes)
            
        meeting = MeetingSession(
            title=meeting_data.title,
            description=meeting_data.description,
            room_name=room_name,
            creator_id=creator.id,
            expires_at=expires_at,
            is_active=True
        )
        
        db.add(meeting)
        await db.commit()
        await db.refresh(meeting)
        return meeting

    @staticmethod
    async def get_active_meetings(db: AsyncSession) -> List[MeetingSession]:
        """
        Lists all active meetings.
        """
        now = datetime.datetime.now(datetime.timezone.utc)
        # Find active sessions, checking expiration time
        query = select(MeetingSession).where(
            MeetingSession.is_active == True,
            (MeetingSession.expires_at == None) | (MeetingSession.expires_at > now)
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def get_meeting_by_room(db: AsyncSession, room_name: str) -> MeetingSession:
        """
        Retrieves a meeting session by room name.
        """
        result = await db.execute(select(MeetingSession).where(MeetingSession.room_name == room_name))
        meeting = result.scalars().first()
        if not meeting:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meeting session not found"
            )
        
        # Check if meeting expired
        now = datetime.datetime.now(datetime.timezone.utc)
        if meeting.expires_at and meeting.expires_at < now:
            meeting.is_active = False
            await db.commit()
            raise HTTPException(
                status_code=status.HTTP_410_GONE,
                detail="Meeting session has expired"
            )
            
        if not meeting.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Meeting session is no longer active"
            )
            
        return meeting

    @staticmethod
    async def end_meeting(db: AsyncSession, room_name: str, user_id: uuid.UUID) -> MeetingSession:
        """
        Deactivates a meeting session. Only the creator or admin/faculty can do this.
        """
        meeting = await MeetingService.get_meeting_by_room(db, room_name)
        if meeting.creator_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the meeting creator can end this meeting"
            )
            
        meeting.is_active = False
        await db.commit()
        await db.refresh(meeting)
        return meeting
