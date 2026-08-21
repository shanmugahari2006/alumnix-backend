import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict

class ChatUserSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str
    email: Optional[str] = None
    role: str
    avatar_url: Optional[str] = None
    company: Optional[str] = None
    designation: Optional[str] = None
    branch: Optional[str] = None
    graduation_year: Optional[int] = None

class MessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    conversation_id: uuid.UUID
    sender_id: uuid.UUID
    sender_name: str
    content: str
    is_read: bool
    created_at: datetime

class SendMessageRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000, description="Message text content")

class StartConversationRequest(BaseModel):
    recipient_id: uuid.UUID

class ConversationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    partner: ChatUserSummary
    last_message: Optional[MessageResponse] = None
    unread_count: int = 0
    created_at: datetime
    updated_at: datetime

class ConversationDetailResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    partner: ChatUserSummary
    messages: List[MessageResponse]
    created_at: datetime
    updated_at: datetime

class UnreadCountResponse(BaseModel):
    total_unread: int
