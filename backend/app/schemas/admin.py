from pydantic import BaseModel
from typing import List
from app.schemas.auth import UserResponse

class AdminStatsResponse(BaseModel):
    total_alumni: int
    pending_alumni_approvals: int
    total_students: int
    total_jobs_posted: int
    total_donations_amount: float
    total_events: int

class AdminUsersPaginatedResponse(BaseModel):
    total: int
    page: int
    limit: int
    results: List[UserResponse]

class UserStatusUpdate(BaseModel):
    is_active: bool
