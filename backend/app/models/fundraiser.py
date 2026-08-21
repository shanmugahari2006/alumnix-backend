import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base

class Fundraiser(Base):
    __tablename__ = "fundraisers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    goal_amount = Column(Integer, nullable=False)
    raised_amount = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
