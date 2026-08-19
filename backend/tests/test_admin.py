import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User, UserRole, Alumni
from app.models.job import JobListing
from app.models.event import Event
from app.models.donation import Donation
import uuid
from datetime import datetime

@pytest.mark.asyncio
async def test_admin_endpoints_restricted(client: AsyncClient):
    # Non-admin student client should receive 403 Forbidden on all routes
    r1 = await client.get("/api/v1/admin/stats")
    assert r1.status_code == 403
    
    r2 = await client.get("/api/v1/admin/users")
    assert r2.status_code == 403
    
    fake_uuid = uuid.uuid4()
    r3 = await client.patch(f"/api/v1/admin/users/{fake_uuid}/status", json={"is_active": False})
    assert r3.status_code == 403

@pytest.mark.asyncio
async def test_admin_stats(admin_client: AsyncClient, db_session: AsyncSession, test_user, test_admin):
    # Let's seed some data to test aggregations
    
    # 1. Add an alumni user
    alumni_user = User(
        id=uuid.uuid4(),
        email="alumni_user@example.com",
        phone_number="+918888888888",
        full_name="Alumni Test",
        role=UserRole.alumni,
        is_active=True
    )
    db_session.add(alumni_user)
    await db_session.commit()
    
    alumni_profile = Alumni(
        id=alumni_user.id,
        graduation_year=2020,
        is_approved=False # Pending approval
    )
    db_session.add(alumni_profile)
    
    # 2. Add a job listing
    job = JobListing(
        title="Software Engineer",
        company="TechCorp",
        description="Great role",
        location="Remote",
        job_type="Full-time",
        creator_id=test_admin.id
    )
    db_session.add(job)
    
    # 3. Add an event
    event = Event(
        title="Alumni Reunion",
        description="Gathering",
        date=datetime.utcnow(),
        location="Main Campus",
        creator_id=test_admin.id
    )
    db_session.add(event)
    
    # 4. Add donations (one completed, one pending)
    d1 = Donation(
        donor_id=test_user.id,
        amount=150.0,
        purpose="Scholarship",
        status="completed",
        razorpay_order_id="ord_comp"
    )
    d2 = Donation(
        donor_id=test_user.id,
        amount=300.0,
        purpose="Labs",
        status="pending",
        razorpay_order_id="ord_pend"
    )
    db_session.add_all([d1, d2])
    await db_session.commit()
    
    response = await admin_client.get("/api/v1/admin/stats")
    assert response.status_code == 200
    data = response.json()
    assert data["total_alumni"] == 1
    assert data["pending_alumni_approvals"] == 1
    assert data["total_students"] == 1  # test_user is student
    assert data["total_jobs_posted"] == 1
    assert data["total_events"] == 1
    assert data["total_donations_amount"] == 150.0

@pytest.mark.asyncio
async def test_admin_list_users(admin_client: AsyncClient, db_session: AsyncSession):
    # Test pagination and filters
    response = await admin_client.get("/api/v1/admin/users?limit=2&page=1")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert len(data["results"]) <= 2
    
    # Filter by role
    res_students = await admin_client.get("/api/v1/admin/users?role=student")
    assert res_students.status_code == 200
    for u in res_students.json()["results"]:
        assert u["role"] == "student"

@pytest.mark.asyncio
async def test_admin_update_user_status(admin_client: AsyncClient, db_session: AsyncSession, test_user):
    # test_user is initially active
    assert test_user.is_active is True
    
    # Block test_user
    response = await admin_client.patch(
        f"/api/v1/admin/users/{test_user.id}/status",
        json={"is_active": False}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["is_active"] is False
    
    # Re-fetch from database to verify persistence
    await db_session.refresh(test_user)
    assert test_user.is_active is False
    
    # Non-existent user status update should return 404
    fake_id = uuid.uuid4()
    r_404 = await admin_client.patch(
        f"/api/v1/admin/users/{fake_id}/status",
        json={"is_active": True}
    )
    assert r_404.status_code == 404
