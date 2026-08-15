from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.auth import router as auth_router
from app.routes.phone_auth import router as phone_router
from app.routes.alumni import router as alumni_router
from app.routes.jobs import router as jobs_router
from app.routes.events import router as events_router
from app.routes.stories import router as stories_router
from app.database import engine, Base
import app.models  # Import to register models on Base.metadata

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Auto-create tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
    # Auto-seed default admin & sample registry records for validation
    from sqlalchemy import select
    from app.models import User, CollegeRecord, UserRole
    from app.utils.security import hash_password
    from app.database import SessionLocal
    
    async with SessionLocal() as session:
        # Seed Admin
        admin_res = await session.execute(
            select(User).where(User.role == UserRole.admin)
        )
        if not admin_res.scalars().first():
            admin_user = User(
                email="admin@college.com",
                phone_number="+919999999999",
                hashed_password=hash_password("admin1234"),
                full_name="System Administrator",
                role=UserRole.admin,
                is_active=True
            )
            session.add(admin_user)
            await session.commit()
            print("Default admin user created: admin@college.com / admin1234")
            
        # Seed Registry
        reg_res = await session.execute(select(CollegeRecord))
        if not reg_res.scalars().first():
            records = [
                CollegeRecord(
                    usn="1RV20CS001",
                    full_name="Munir Student",
                    email="student@college.com",
                    phone_number="+919876543210",
                    role=UserRole.student,
                    branch="Computer Science",
                    graduation_year=2026
                ),
                CollegeRecord(
                    usn="1RV20CS002",
                    full_name="Alumni User",
                    email="alumni@college.com",
                    phone_number="+918765432109",
                    role=UserRole.alumni,
                    branch="Computer Science",
                    graduation_year=2020
                )
            ]
            session.add_all(records)
            await session.commit()
            print("Sample college registry records seeded: 1RV20CS001 (Student), 1RV20CS002 (Alumni)")
            
    yield

app = FastAPI(title="AlumniConnect API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(phone_router, prefix="/api/v1/auth", tags=["Phone Authentication"])

app.include_router(alumni_router, prefix="/api/v1/alumni", tags=["Alumni Directory"])
app.include_router(jobs_router, prefix="/api/v1/jobs", tags=["Job Portal"])
app.include_router(events_router, prefix="/api/v1/events", tags=["Events"])
app.include_router(stories_router, prefix="/api/v1/stories", tags=["Success Stories"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "app": "AlumniConnect"}
