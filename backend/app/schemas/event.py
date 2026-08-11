import uuid
from datetime import datetime
from pydantic import BaseModel, Field

class EventCreate(BaseModel):
    title: str = Field(..., min_length=1)
    description: str = Field(..., min_length=1)
    date: datetime
    location: str = Field(..., min_length=1)

class EventResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: str
    date: datetime
    location: str
    creator_id: uuid.UUID
    created_at: datetime
    model_config = {"from_attributes": True}

class EventRegistrationResponse(BaseModel):
    id: uuid.UUID
    event_id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    model_config = {"from_attributes": True}

class AttendeeDetail(BaseModel):
    id: uuid.UUID
    full_name: str
    email: str
    role: str
    model_config = {"from_attributes": True}
