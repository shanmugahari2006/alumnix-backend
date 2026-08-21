import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, UUID, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

class MeetingSession(Base):
    __tablename__ = "meeting_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    room_name = Column(String, unique=True, index=True, nullable=False)
    creator_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    expires_at = Column(DateTime, nullable=True)
    
    creator = relationship("User")
