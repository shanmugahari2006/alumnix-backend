import uuid
from pydantic import BaseModel, Field, EmailStr
from app.schemas.auth import UserResponse, FacultyProfileResponse

class FacultyRegister(BaseModel):
    email: EmailStr = Field(..., description="Email address")
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")
    full_name: str = Field(..., min_length=1, description="Full Name")
    employee_id: str = Field(..., min_length=1)
    department: str = Field(..., min_length=1)
    designation: str = Field(..., min_length=1)

class FacultyResponse(BaseModel):
    user: UserResponse
    faculty: FacultyProfileResponse
