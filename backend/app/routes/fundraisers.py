from fastapi import APIRouter
from pydantic import BaseModel
import uuid

router = APIRouter()

class FundraiserCreate(BaseModel):
    title: str
    description: str
    goal_amount: int

class DonateRequest(BaseModel):
    amount: int

# In-memory database of campaigns
fundraisers_db = [
    {
        "id": "1",
        "title": "Smart Campus IoT",
        "description": "An automated IoT system to monitor energy and water usage across our college campus.",
        "current_amount": 15000,
        "raised_amount": 15000,
        "goal_amount": 50000
    },
    {
        "id": "2",
        "title": "Eco-friendly E-Bike Sharing",
        "description": "An eco-friendly bike-sharing initiative designed specifically for student commutes between campuses.",
        "current_amount": 80000,
        "raised_amount": 80000,
        "goal_amount": 100000
    },
    {
        "id": "3",
        "title": "Alumni Scholarship Fund",
        "description": "Sponsor textbooks, lab equipment, and tuition fees for students showing academic excellence.",
        "current_amount": 45000,
        "raised_amount": 45000,
        "goal_amount": 150000
    }
]

@router.get("")
async def get_fundraisers():
    return fundraisers_db

@router.post("")
async def create_fundraiser(payload: FundraiserCreate):
    new_campaign = {
        "id": str(uuid.uuid4()),
        "title": payload.title,
        "description": payload.description,
        "current_amount": 0,
        "raised_amount": 0,
        "goal_amount": payload.goal_amount
    }
    fundraisers_db.append(new_campaign)
    return new_campaign

@router.post("/{id}/donate")
async def donate_to_campaign(id: str, payload: DonateRequest):
    for campaign in fundraisers_db:
        if campaign["id"] == id:
            campaign["current_amount"] += payload.amount
            campaign["raised_amount"] += payload.amount
            return campaign
    return {"error": "Campaign not found"}
