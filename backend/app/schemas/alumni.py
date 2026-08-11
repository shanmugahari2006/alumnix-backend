import uuid
from typing import List, Optional
from pydantic import BaseModel

class AlumniProfileUpdate(BaseModel):
    company: Optional[str] = None
    designation: Optional[str] = None
    location: Optional[str] = None
    linkedin_url: Optional[str] = None
    skills: Optional[List[str]] = None
    branch: Optional[str] = None

class AlumniSearchResult(BaseModel):
    id: uuid.UUID
    full_name: str
    email: str
    company: Optional[str] = None
    designation: Optional[str] = None
    graduation_year: int
    branch: Optional[str] = None
    location: Optional[str] = None
    linkedin_url: Optional[str] = None
    skills: Optional[List[str]] = None
    model_config = {"from_attributes": True}

class AlumniPaginatedResponse(BaseModel):
    total: int
    page: int
    limit: int
    results: List[AlumniSearchResult]
