import re
from pydantic import BaseModel, Field, field_validator

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")

class UserRegister(BaseModel):
    email: str = Field(..., description="Email address")
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")
    full_name: str = Field(..., min_length=1, description="Full Name")

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        v = v.strip().lower()
        if not EMAIL_REGEX.match(v):
            raise ValueError("Invalid email format")
        return v

class StudentRegister(UserRegister):
    roll_number: str = Field(..., min_length=1)
    branch: str = Field(..., min_length=1)
    graduation_year: int = Field(..., ge=1900, le=2100)

class AlumniRegister(UserRegister):
    graduation_year: int = Field(..., ge=1900, le=2100)
    company: str = Field(..., min_length=1)
    designation: str = Field(..., min_length=1)

class UserLogin(BaseModel):
    email: str = Field(...)
    password: str = Field(..., min_length=8)

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        v = v.strip().lower()
        if not EMAIL_REGEX.match(v):
            raise ValueError("Invalid email format")
        return v

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class PasswordResetRequest(BaseModel):
    email: str

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        v = v.strip().lower()
        if not EMAIL_REGEX.match(v):
            raise ValueError("Invalid email format")
        return v

import uuid
from typing import Optional

class StudentProfileResponse(BaseModel):
    roll_number: str
    branch: str
    graduation_year: int
    model_config = {"from_attributes": True}

class AlumniProfileResponse(BaseModel):
    company: str
    designation: str
    graduation_year: int
    is_approved: bool
    model_config = {"from_attributes": True}

class FacultyProfileResponse(BaseModel):
    id: uuid.UUID
    employee_id: str
    department: str
    designation: str
    model_config = {"from_attributes": True}

class UserResponse(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: str
    is_active: bool
    model_config = {"from_attributes": True}

class StudentUserResponse(BaseModel):
    user: UserResponse
    student: StudentProfileResponse

class AlumniUserResponse(BaseModel):
    user: UserResponse
    alumni: AlumniProfileResponse

class UserMeResponse(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: str
    is_active: bool
    student_profile: Optional[StudentProfileResponse] = None
    alumni_profile: Optional[AlumniProfileResponse] = None
    faculty_profile: Optional[FacultyProfileResponse] = None
    model_config = {"from_attributes": True}


