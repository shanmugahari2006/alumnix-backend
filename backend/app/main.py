from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.auth import router as auth_router
from app.routes.alumni import router as alumni_router
from app.routes.jobs import router as jobs_router
from app.routes.events import router as events_router
from app.routes.stories import router as stories_router

app = FastAPI(title="AlumniConnect API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(alumni_router, prefix="/api/v1/alumni", tags=["Alumni Directory"])
app.include_router(jobs_router, prefix="/api/v1/jobs", tags=["Job Portal"])
app.include_router(events_router, prefix="/api/v1/events", tags=["Events"])
app.include_router(stories_router, prefix="/api/v1/stories", tags=["Success Stories"])

@app.get("/health")
async def health_check():
    return {"status": "ok", "app": "AlumniConnect"}
