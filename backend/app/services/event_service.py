import uuid
from typing import List
from fastapi import HTTPException
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.event import Event, EventRegistration
from app.schemas.event import EventCreate

class EventService:
    @staticmethod
    async def create_event(db: AsyncSession, event_data: EventCreate, creator_id: uuid.UUID) -> Event:
        """
        Creates a new event listing in the database.
        """
        event = Event(
            title=event_data.title,
            description=event_data.description,
            date=event_data.date,
            location=event_data.location,
            creator_id=creator_id
        )
        db.add(event)
        await db.commit()
        await db.refresh(event)
        return event

    @staticmethod
    async def list_events(db: AsyncSession) -> List[Event]:
        """
        Lists all events ordered by date descending.
        """
        result = await db.execute(select(Event).order_by(Event.date.desc()))
        return result.scalars().all()

    @staticmethod
    async def register_for_event(db: AsyncSession, event_id: uuid.UUID, user_id: uuid.UUID) -> EventRegistration:
        """
        Registers a user to attend an event. Checks for duplicates.
        """
        # Check event
        event_res = await db.execute(select(Event).where(Event.id == event_id))
        if not event_res.scalars().first():
            raise HTTPException(status_code=404, detail="Event not found")
            
        # Check registration
        reg_res = await db.execute(
            select(EventRegistration).where(EventRegistration.event_id == event_id, EventRegistration.user_id == user_id)
        )
        if reg_res.scalars().first():
            raise HTTPException(status_code=400, detail="You are already registered for this event")

        reg = EventRegistration(event_id=event_id, user_id=user_id)
        db.add(reg)
        await db.commit()
        await db.refresh(reg)
        return reg

    @staticmethod
    async def get_attendees(db: AsyncSession, event_id: uuid.UUID) -> List[EventRegistration]:
        """
        Retrieves all registrations and eager loads user details.
        """
        event_res = await db.execute(select(Event).where(Event.id == event_id))
        if not event_res.scalars().first():
            raise HTTPException(status_code=404, detail="Event not found")
            
        query = select(EventRegistration).where(EventRegistration.event_id == event_id).options(
            selectinload(EventRegistration.user)
        )
        result = await db.execute(query)
        return result.scalars().all()
