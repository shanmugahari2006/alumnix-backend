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
    goal_amount: float
    raised_amount: float

    class Config:
        from_attributes = True

@router.get("", response_model=List[FundraiserResponse])
async def get_fundraisers(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Fundraiser).order_by(Fundraiser.created_at.desc()))
    fundraisers = result.scalars().all()
    
    # If the database is completely empty (unlikely since you raised a fund before, but a safe guard), seed the defaults
    if not fundraisers:
        default_campaigns = [
            Fundraiser(
                title="Smart Campus IoT",
                description="An automated IoT system to monitor energy and water usage across our college campus.",
                target_amount=50000.0,
                current_amount=15000.0,
                status="active"
            ),
            Fundraiser(
                title="Eco-friendly E-Bike Sharing",
                description="An eco-friendly bike-sharing initiative designed specifically for student commutes between campuses.",
                target_amount=100000.0,
                current_amount=80000.0,
                status="active"
            ),
            Fundraiser(
                title="Alumni Scholarship Fund",
                description="Sponsor textbooks, lab equipment, and tuition fees for students showing academic excellence.",
                target_amount=150000.0,
                current_amount=45000.0,
                status="active"
            )
        ]
        db.add_all(default_campaigns)
        await db.commit()
        
        # Re-fetch
        result = await db.execute(select(Fundraiser).order_by(Fundraiser.created_at.desc()))
        fundraisers = result.scalars().all()
        
    return [
        FundraiserResponse(
            id=f.id,
            title=f.title,
            description=f.description,
            goal_amount=f.target_amount,
            raised_amount=f.current_amount
        )
        for f in fundraisers
    ]

@router.post("", response_model=FundraiserResponse, status_code=status.HTTP_201_CREATED)
async def create_fundraiser(
    payload: FundraiserCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    new_campaign = Fundraiser(
        title=payload.title,
        description=payload.description,
        target_amount=payload.goal_amount,
        current_amount=0.0,
        student_id=current_user.id,
        status="active"
    )
    db.add(new_campaign)
    await db.commit()
    await db.refresh(new_campaign)
    
    return FundraiserResponse(
        id=new_campaign.id,
        title=new_campaign.title,
        description=new_campaign.description,
        goal_amount=new_campaign.target_amount,
        raised_amount=new_campaign.current_amount
    )

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
        
    campaign.current_amount += payload.amount
    await db.commit()
    await db.refresh(campaign)
    
    return FundraiserResponse(
        id=campaign.id,
        title=campaign.title,
        description=campaign.description,
        goal_amount=campaign.target_amount,
        raised_amount=campaign.current_amount
    )
