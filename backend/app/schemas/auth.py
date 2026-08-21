import re
from pydantic import BaseModel, Field, field_validator, model_validator

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



class UserLogin(BaseModel):
    email: str = Field(...)
    password: str = Field(..., min_length=8)

    @field_validator("email")
    @classmethod
    def validate_email_or_phone(cls, v: str) -> str:
        v = v.strip().lower()
        if "@" in v:
            if not EMAIL_REGEX.match(v):
                raise ValueError("Invalid email format")
            return v
        
        # Phone number validation: extract only digits
        phone_clean = re.sub(r"\D", "", v)
        if len(phone_clean) >= 10:
            return phone_clean[-10:] # Return only the last 10 numbers
        raise ValueError("Must be a valid email or 10-digit phone number")
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
from typing import Optional, List

class StudentProfileResponse(BaseModel):
    usn: str
    branch: str
    graduation_year: int
    model_config = {"from_attributes": True}

class AlumniProfileResponse(BaseModel):
    usn: Optional[str] = None
    company: Optional[str] = None
    designation: Optional[str] = None
    graduation_year: int
    branch: Optional[str] = None
    location: Optional[str] = None
    linkedin_url: Optional[str] = None
    skills: Optional[List[str]] = None
    is_approved: bool
    model_config = {"from_attributes": True}

class FacultyProfileResponse(BaseModel):
    id: uuid.UUID
    employee_id: str
    department: str
    designation: str
    is_approved: bool
    model_config = {"from_attributes": True}

from app.models.user import UserRole, AuthProviderType

class UserResponse(BaseModel):
    id: uuid.UUID
    email: Optional[str] = None
    phone_number: Optional[str] = None
    avatar_url: Optional[str] = None
    full_name: str
    role: UserRole
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
    email: Optional[str] = None
    phone_number: Optional[str] = None
    avatar_url: Optional[str] = None
    full_name: str
    role: UserRole
    is_active: bool
    student_profile: Optional[StudentProfileResponse] = None
    alumni_profile: Optional[AlumniProfileResponse] = None
    faculty_profile: Optional[FacultyProfileResponse] = None
    model_config = {"from_attributes": True}

class PhoneOTPRequest(BaseModel):
    phone_number: str = Field(..., min_length=1, description="Phone number to send OTP to")

class PhoneOTPVerify(BaseModel):
    phone_number: str = Field(..., min_length=1, description="Registered phone number")
    otp_code: str = Field(..., min_length=4, max_length=8, description="Verification OTP code received")

class ForgotPasswordRequest(BaseModel):
    email: Optional[str] = None
    phone_number: Optional[str] = None

    @model_validator(mode="after")
    def check_identifier(self) -> "ForgotPasswordRequest":
        if not self.email and not self.phone_number:
            raise ValueError("Either email or phone_number must be provided")
        if self.email and self.phone_number:
            raise ValueError("Provide either email or phone_number, not both")
        return self

class ResetPasswordRequest(BaseModel):
    email: Optional[str] = None
    phone_number: Optional[str] = None
    code: str = Field(..., min_length=4, max_length=8, description="Reset code or OTP code")
    new_password: str = Field(..., min_length=8, description="New account password")

    @model_validator(mode="after")
    def check_identifier(self) -> "ResetPasswordRequest":
        if not self.email and not self.phone_number:
            raise ValueError("Either email or phone_number must be provided")
        if self.email and self.phone_number:
            raise ValueError("Provide either email or phone_number, not both")
        return self

class VerifyUSNRequest(BaseModel):
    usn: str = Field(..., min_length=1, description="Student/Alumni University Seat Number")
    role: UserRole = Field(..., description="Role to verify against the registry (student or alumni)")

class VerifyUSNResponse(BaseModel):
    full_name: str

class SendSocialOTPRequest(BaseModel):
    usn: str = Field(..., min_length=1)
    channel: str = Field(..., description="Channel to send OTP to ('email' or 'phone')")

class VerifySocialOTPRequest(BaseModel):
    usn: str = Field(..., min_length=1)
    channel: str = Field(..., description="Channel the OTP was sent to ('email' or 'phone')")
    otp_code: str = Field(..., min_length=4, max_length=8)

class VerifySocialOTPResponse(BaseModel):
    verification_token: str

class SetupPasswordRequest(BaseModel):
    verification_token: str = Field(..., min_length=1)
    password: str = Field(..., min_length=8)





