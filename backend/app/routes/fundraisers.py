from fastapi import APIRouter
import uuid

router = APIRouter()

@router.get("")
async def get_fundraisers():
    return [
        {
            "id": str(uuid.uuid4()),
            "title": "Smart Campus IoT",
            "description": "An automated IoT system to monitor energy and water usage across our college campus.",
            "current_amount": 15000,
            "raised_amount": 15000,
            "goal_amount": 50000
        },
        {
            "id": str(uuid.uuid4()),
            "title": "Eco-friendly E-Bike Sharing",
            "description": "An eco-friendly bike-sharing initiative designed specifically for student commutes between campuses.",
            "current_amount": 80000,
            "raised_amount": 80000,
            "goal_amount": 100000
        },
        {
            "id": str(uuid.uuid4()),
            "title": "Alumni Scholarship Fund",
            "description": "Sponsor textbooks, lab equipment, and tuition fees for students showing academic excellence.",
            "current_amount": 45000,
            "raised_amount": 45000,
            "goal_amount": 150000
        }
    ]
