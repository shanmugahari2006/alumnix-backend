from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.fundraiser import Fundraiser
from app.dependencies import get_current_user
from app.models.user import User
import uuid
from typing import List

router = APIRouter()

class FundraiserCreate(BaseModel):
    title: str
    description: str
    goal_amount: int

class DonateRequest(BaseModel):
    amount: int

class FundraiserResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: str
    goal_amount: int
    raised_amount: int

    class Config:
        from_attributes = True

@router.get("", response_model=List[FundraiserResponse])
async def get_fundraisers(db: AsyncSession = Depends(get_db)):
    # Query all fundraisers
    result = await db.execute(select(Fundraiser).order_by(Fundraiser.created_at.desc()))
    fundraisers = result.scalars().all()
    
    # If database has no campaigns, seed the default 3
    if not fundraisers:
        default_campaigns = [
            Fundraiser(
                title="Smart Campus IoT",
                description="An automated IoT system to monitor energy and water usage across our college campus.",
                goal_amount=50000,
                raised_amount=15000
            ),
            Fundraiser(
                title="Eco-friendly E-Bike Sharing",
                description="An eco-friendly bike-sharing initiative designed specifically for student commutes between campuses.",
                goal_amount=100000,
                raised_amount=80000
            ),
            Fundraiser(
                title="Alumni Scholarship Fund",
                description="Sponsor textbooks, lab equipment, and tuition fees for students showing academic excellence.",
                goal_amount=150000,
                raised_amount=45000
            )
        ]
        db.add_all(default_campaigns)
        await db.commit()
        
        # Re-fetch
        result = await db.execute(select(Fundraiser).order_by(Fundraiser.created_at.desc()))
        fundraisers = result.scalars().all()
        
    return fundraisers

@router.post("", response_model=FundraiserResponse, status_code=status.HTTP_201_CREATED)
async def create_fundraiser(
    payload: FundraiserCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    new_campaign = Fundraiser(
        title=payload.title,
        description=payload.description,
        goal_amount=payload.goal_amount,
        raised_amount=0
    )
    db.add(new_campaign)
    await db.commit()
    await db.refresh(new_campaign)
    return new_campaign

@router.post("/{id}/donate", response_model=FundraiserResponse)
async def donate_to_campaign(
    id: uuid.UUID,
    payload: DonateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Fundraiser).where(Fundraiser.id == id))
    campaign = result.scalars().first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
        
    campaign.raised_amount += payload.amount
    await db.commit()
    await db.refresh(campaign)
    return campaign
