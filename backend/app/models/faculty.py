import uuid
from sqlalchemy import Column, String, ForeignKey, UUID
from sqlalchemy.orm import relationship
from app.database import Base

class Faculty(Base):
    __tablename__ = "faculty"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    employee_id = Column(String, unique=True, index=True, nullable=False)
    department = Column(String, nullable=False)
    designation = Column(String, nullable=False)
    
    user = relationship("User", back_populates="faculty_profile")
