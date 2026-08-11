import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.user import User
from app.schemas.job import (
    JobCreate, JobResponse, ApplyJobRequest, JobApplicationResponse,
    JobApplicationDetailResponse, UpdateApplicationStatus
)
from app.schemas.auth import StudentUserResponse, UserResponse, StudentProfileResponse
from app.services.job_service import JobService
from app.dependencies import get_current_user, require_role

router = APIRouter()

@router.post("", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
async def create_job(
    payload: JobCreate,
    current_user: User = Depends(require_role(["alumni", "admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Post a new job listing. Restricted to Alumni and Admin users.
    """
    job = await JobService.create_job(db, payload, current_user.id)
    return job

@router.get("", response_model=List[JobResponse])
async def list_jobs(
    title: Optional[str] = None,
    company: Optional[str] = None,
    job_type: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    List all job listings. Filters by title, company, or job_type.
    """
    jobs = await JobService.list_jobs(db, title=title, company=company, job_type=job_type)
    return jobs

@router.post("/{job_id}/apply", response_model=JobApplicationResponse, status_code=status.HTTP_201_CREATED)
async def apply_to_job(
    job_id: uuid.UUID,
    payload: ApplyJobRequest,
    current_user: User = Depends(require_role(["student"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Submit a job application. Restricted to Student users.
    """
    application = await JobService.apply_to_job(db, job_id, current_user.id, payload)
    return application

@router.get("/{job_id}/applications", response_model=List[JobApplicationDetailResponse])
async def get_job_applications(
    job_id: uuid.UUID,
    current_user: User = Depends(require_role(["alumni", "admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    List all candidates who applied to a specific job listing. Restricted to job creator or Admin.
    """
    applications = await JobService.get_applications(db, job_id, current_user.id, current_user.role)
    
    # Map applicant details to nested response schema
    detail_responses = []
    for app_item in applications:
        student_user = app_item.student
        student_profile = student_user.student_profile
        
        detail_responses.append(JobApplicationDetailResponse(
            id=app_item.id,
            job_id=app_item.job_id,
            resume_url=app_item.resume_url,
            status=app_item.status,
            created_at=app_item.created_at,
            student=StudentUserResponse(
                user=UserResponse.model_validate(student_user),
                student=StudentProfileResponse.model_validate(student_profile)
            )
        ))
    return detail_responses

@router.patch("/applications/{application_id}/status", response_model=JobApplicationResponse)
async def update_application_status(
    application_id: uuid.UUID,
    payload: UpdateApplicationStatus,
    current_user: User = Depends(require_role(["alumni", "admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Update the status of a job application (e.g. shortlist or reject). Restricted to job creator or Admin.
    """
    updated_app = await JobService.update_application_status(
        db, application_id, payload, current_user.id, current_user.role
    )
    return updated_app
