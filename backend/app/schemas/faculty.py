from typing import Optional
from pydantic import BaseModel, Field, model_validator
from app.schemas.auth import UserResponse, FacultyProfileResponse

class FacultyRegister(BaseModel):
    employee_id: str = Field(..., min_length=1)
    full_name: str = Field(..., min_length=1)
    email: Optional[str] = None
    phone_number: Optional[str] = None
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")
    department: str = Field(..., min_length=1)
    designation: str = Field(..., min_length=1)

    @model_validator(mode="after")
    def check_contact(self) -> 'FacultyRegister':
        if not self.email and not self.phone_number:
            raise ValueError("Either email or phone_number must be provided")
        return self

class FacultyResponse(BaseModel):
    user: UserResponse
    faculty: FacultyProfileResponse
