import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.user import User
from app.dependencies import get_current_user
from app.schemas.donation import (
    DonationCreate,
    DonationOrderResponse,
    DonationVerify,
    DonationVerifyResponse,
    DonationResponse
)
from app.services.payment_service import PaymentService
from app.config import settings

router = APIRouter()

@router.post("/create-order", response_model=DonationOrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    payload: DonationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new donation order with Razorpay and store it in the database.
    """
    donation = await PaymentService.create_donation_order(
        db=db,
        donor_id=current_user.id,
        amount=payload.amount,
        purpose=payload.purpose
    )
    return DonationOrderResponse(
        order_id=donation.razorpay_order_id,
        amount=donation.amount,
        currency=donation.currency,
        key_id=settings.RAZORPAY_KEY_ID
    )

@router.post("/verify", response_model=DonationVerifyResponse)
async def verify_payment(
    payload: DonationVerify,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Verify signature of the Razorpay payment.
    """
    donation = await PaymentService.verify_donation_payment(
        db=db,
        razorpay_order_id=payload.razorpay_order_id,
        razorpay_payment_id=payload.razorpay_payment_id,
        razorpay_signature=payload.razorpay_signature
    )
    return DonationVerifyResponse(
        status="success",
        message="Payment verified and completed successfully",
        donation_id=donation.id
    )

@router.get("/my-donations", response_model=List[DonationResponse])
async def get_my_donations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve historical donations for the current logged-in donor.
    """
    donations = await PaymentService.get_user_donations(db=db, donor_id=current_user.id)
    return donations
