import uuid
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from app.models.job import JobListing, JobApplication
from app.schemas.job import JobCreate, ApplyJobRequest, UpdateApplicationStatus

class JobService:
    @staticmethod
    async def create_job(db: AsyncSession, job_data: JobCreate, creator_id: uuid.UUID) -> JobListing:
        """
        Creates a new job listing record.
        """
        job = JobListing(
            title=job_data.title,
            company=job_data.company,
            description=job_data.description,
            location=job_data.location,
            job_type=job_data.job_type,
            salary=job_data.salary,
            creator_id=creator_id
        )
        db.add(job)
        await db.commit()
        await db.refresh(job)
        return job

    @staticmethod
    async def list_jobs(
        db: AsyncSession,
        title: Optional[str] = None,
        company: Optional[str] = None,
        job_type: Optional[str] = None
    ) -> List[JobListing]:
        """
        Retrieves all job listings with title, company, or job_type filtering.
        """
        query = select(JobListing)
        filters = []
        if title:
            filters.append(JobListing.title.ilike(f"%{title}%"))
        if company:
            filters.append(JobListing.company.ilike(f"%{company}%"))
        if job_type:
            filters.append(JobListing.job_type.ilike(f"%{job_type}%"))
            
        if filters:
            query = query.where(*filters)
            
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def apply_to_job(
        db: AsyncSession,
        job_id: uuid.UUID,
        student_id: uuid.UUID,
        payload: ApplyJobRequest
    ) -> JobApplication:
        """
        Submits a job application for a student, checking for existing applications first.
        """
        # Check if job exists
        job_res = await db.execute(select(JobListing).where(JobListing.id == job_id))
        if not job_res.scalars().first():
            raise HTTPException(status_code=404, detail="Job listing not found")
            
        # Check if already applied
        app_res = await db.execute(
            select(JobApplication).where(JobApplication.job_id == job_id, JobApplication.student_id == student_id)
        )
        if app_res.scalars().first():
            raise HTTPException(status_code=400, detail="You have already applied to this job")

        application = JobApplication(
            job_id=job_id,
            student_id=student_id,
            resume_url=payload.resume_url,
            status="applied"
        )
        db.add(application)
        await db.commit()
        await db.refresh(application)
        return application

    @staticmethod
    async def get_applications(
        db: AsyncSession,
        job_id: uuid.UUID,
        user_id: uuid.UUID,
        user_role: str
    ) -> List[JobApplication]:
        """
        Returns all applications for a job listing, restricting results to the creator or admins.
        """
        # Fetch job details to check creator
        job_res = await db.execute(select(JobListing).where(JobListing.id == job_id))
        job = job_res.scalars().first()
        if not job:
            raise HTTPException(status_code=404, detail="Job listing not found")
            
        # Creator or Admin checking
        if user_role != "admin" and job.creator_id != user_id:
            raise HTTPException(status_code=403, detail="Permission denied: Not the job creator")

        # Query and eager load user and nested student profiles
        query = select(JobApplication).where(JobApplication.job_id == job_id).options(
            selectinload(JobApplication.student).selectinload(User.student_profile)
        )
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def update_application_status(
        db: AsyncSession,
        application_id: uuid.UUID,
        payload: UpdateApplicationStatus,
        user_id: uuid.UUID,
        user_role: str
    ) -> JobApplication:
        """
        Updates the status of a job application (restricted to job creator or admins).
        """
        # Load application with job context
        query = select(JobApplication).where(JobApplication.id == application_id).options(
            selectinload(JobApplication.job)
        )
        res = await db.execute(query)
        application = res.scalars().first()
        if not application:
            raise HTTPException(status_code=404, detail="Job application not found")
            
        # Verify access authorization
        if user_role != "admin" and application.job.creator_id != user_id:
            raise HTTPException(status_code=403, detail="Permission denied: Not the job creator")

        application.status = payload.status
        await db.commit()
        await db.refresh(application)
        return application
