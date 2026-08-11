import uuid
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, UUID, JSON
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(String, nullable=False)  # "student", "alumni", "faculty", "admin"
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    student_profile = relationship("Student", back_populates="user", uselist=False, cascade="all, delete-orphan")
    alumni_profile = relationship("Alumni", back_populates="user", uselist=False, cascade="all, delete-orphan")
    faculty_profile = relationship("Faculty", back_populates="user", uselist=False, cascade="all, delete-orphan")

class Student(Base):
    __tablename__ = "students"
    
    id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    roll_number = Column(String, unique=True, index=True, nullable=False)
    branch = Column(String, nullable=False)
    graduation_year = Column(Integer, nullable=False)
    
    user = relationship("User", back_populates="student_profile")

class Alumni(Base):
    __tablename__ = "alumni"
    
    id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    company = Column(String, nullable=False)
    designation = Column(String, nullable=False)
    graduation_year = Column(Integer, nullable=False)
    branch = Column(String, nullable=True)
    location = Column(String, nullable=True)
    linkedin_url = Column(String, nullable=True)
    skills = Column(JSON, nullable=True)
    is_approved = Column(Boolean, default=False)
    
    user = relationship("User", back_populates="alumni_profile")
