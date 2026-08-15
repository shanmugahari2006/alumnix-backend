import uuid
import enum
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, UUID, JSON, Enum, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

class UserRole(enum.Enum):
    student = "student"
    alumni = "alumni"
    faculty = "faculty"
    admin = "admin"

class AuthProviderType(enum.Enum):
    email = "email"
    google = "google"
    linkedin = "linkedin"
    phone = "phone"

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=True)
    phone_number = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String, nullable=True)
    full_name = Column(String, nullable=False)
    avatar_url = Column(String, nullable=True)
    role = Column(Enum(UserRole), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    student_profile = relationship("Student", back_populates="user", uselist=False, cascade="all, delete-orphan")
    alumni_profile = relationship("Alumni", back_populates="user", uselist=False, cascade="all, delete-orphan")
    faculty_profile = relationship("Faculty", back_populates="user", uselist=False, cascade="all, delete-orphan")
    auth_providers = relationship("AuthProvider", back_populates="user", cascade="all, delete-orphan")

class AuthProvider(Base):
    __tablename__ = "auth_providers"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    provider = Column(Enum(AuthProviderType), nullable=False)
    provider_user_id = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        UniqueConstraint('provider', 'provider_user_id', name='uq_provider_provider_user_id'),
    )
    
    user = relationship("User", back_populates="auth_providers")

class CollegeRecord(Base):
    __tablename__ = "college_records"
    
    usn = Column(String, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, nullable=False)
    phone_number = Column(String, nullable=False)
    role = Column(Enum(UserRole), nullable=False)
    branch = Column(String, nullable=False)
    graduation_year = Column(Integer, nullable=False)

class Student(Base):
    __tablename__ = "students"
    
    id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    usn = Column(String, unique=True, index=True, nullable=False)
    branch = Column(String, nullable=False)
    graduation_year = Column(Integer, nullable=False)
    
    user = relationship("User", back_populates="student_profile")

class Alumni(Base):
    __tablename__ = "alumni"
    
    id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    usn = Column(String, unique=True, index=True, nullable=True)
    company = Column(String, nullable=True)
    designation = Column(String, nullable=True)
    graduation_year = Column(Integer, nullable=False)
    branch = Column(String, nullable=True)
    location = Column(String, nullable=True)
    linkedin_url = Column(String, nullable=True)
    skills = Column(JSON, nullable=True)
    is_approved = Column(Boolean, default=False)
    
    user = relationship("User", back_populates="alumni_profile")
