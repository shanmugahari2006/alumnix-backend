import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime, UUID
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

class JobListing(Base):
    __tablename__ = "jobs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    company = Column(String, nullable=False)
    description = Column(String, nullable=False)
    location = Column(String, nullable=False)
    job_type = Column(String, nullable=False) # e.g., "Full-time", "Internship"
    salary = Column(String, nullable=True)
    creator_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    creator = relationship("User")
    applications = relationship("JobApplication", back_populates="job", cascade="all, delete-orphan")

    @property
    def creator_name(self):
        return self.creator.full_name if self.creator else "Alumnix Member"

class JobApplication(Base):
    __tablename__ = "job_applications"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    job_id = Column(UUID(as_uuid=True), ForeignKey("jobs.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    resume_url = Column(String, nullable=False)
    status = Column(String, default="applied") # "applied", "shortlisted", "rejected"
    created_at = Column(DateTime, default=datetime.utcnow)
    
    job = relationship("JobListing", back_populates="applications")
    student = relationship("User")
