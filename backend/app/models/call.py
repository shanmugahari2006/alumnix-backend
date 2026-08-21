import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, UUID, text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Call(Base):
    __tablename__ = "calls"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, server_default=text("gen_random_uuid()"))
    caller_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    receiver_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    room_id = Column(String, nullable=False)
    status = Column(String, nullable=False)  # ringing, connected, rejected, ended, missed
    created_at = Column(DateTime, default=datetime.utcnow, server_default=text("now()"), nullable=False)
    started_at = Column(DateTime, nullable=True)
    ended_at = Column(DateTime, nullable=True)

    caller = relationship("User", foreign_keys=[caller_id], backref="outgoing_calls")
    receiver = relationship("User", foreign_keys=[receiver_id], backref="incoming_calls")
