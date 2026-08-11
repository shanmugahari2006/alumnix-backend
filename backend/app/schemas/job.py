import uuid
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field, field_validator
from app.schemas.auth import StudentUserResponse

class JobCreate(BaseModel):
    title: str = Field(..., min_length=1)
    company: str = Field(..., min_length=1)
    description: str = Field(..., min_length=1)
    location: str = Field(..., min_length=1)
    job_type: str = Field(..., min_length=1)
    salary: Optional[str] = None

class JobResponse(BaseModel):
    id: uuid.UUID
    title: str
    company: str
    description: str
    location: str
    job_type: str
    salary: Optional[str]
    creator_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    model_config = {"from_attributes": True}

class ApplyJobRequest(BaseModel):
    resume_url: str = Field(..., min_length=1)

class JobApplicationResponse(BaseModel):
    id: uuid.UUID
    job_id: uuid.UUID
    student_id: uuid.UUID
    resume_url: str
    status: str
    created_at: datetime
    model_config = {"from_attributes": True}

class JobApplicationDetailResponse(BaseModel):
    id: uuid.UUID
    job_id: uuid.UUID
    resume_url: str
    status: str
    created_at: datetime
    student: StudentUserResponse
    model_config = {"from_attributes": True}

class UpdateApplicationStatus(BaseModel):
    status: str = Field(...)

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        valid_statuses = ["shortlisted", "rejected"]
        if v not in valid_statuses:
            raise ValueError(f"Status must be one of {valid_statuses}")
        return v
