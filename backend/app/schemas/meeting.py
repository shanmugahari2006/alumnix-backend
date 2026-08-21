import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class MeetingCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=100, description="Meeting title")
    description: Optional[str] = Field(None, max_length=500, description="Meeting description")
    expires_in_minutes: Optional[int] = Field(120, description="Meeting duration in minutes")

class MeetingResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: Optional[str]
    room_name: str
    creator_id: uuid.UUID
    is_active: bool
    created_at: datetime
    expires_at: Optional[datetime]
    jitsi_url: str
    token: str

    model_config = {
        "from_attributes": True
    }

class MeetingJoinResponse(BaseModel):
    room_name: str
    token: str
    jitsi_url: str

    model_config = {
        "from_attributes": True
    }
