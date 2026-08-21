import uuid
import asyncio
import razorpay
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.config import settings
from app.models.donation import Donation

# Initialize the Razorpay client with configurations
razorpay_client = razorpay.Client(auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET))

class PaymentService:
    @staticmethod
    async def create_donation_order(
        db: AsyncSession, 
        donor_id: uuid.UUID, 
        amount: float, 
        purpose: str
    ) -> Donation:
        """
        Creates an official Razorpay Order and stores a pending donation record.
        """
        # Amount in Razorpay is expected in subunits (paise for INR)
        amount_in_paise = int(amount * 100)
        receipt_id = f"rcpt_{uuid.uuid4().hex[:10]}"
        
        order_data = {
            "amount": amount_in_paise,
            "currency": "INR",
            "receipt": receipt_id
        }
        
        if settings.RAZORPAY_KEY_ID == "your_razorpay_key_id" or not settings.RAZORPAY_KEY_ID:
            razorpay_order = {
                "id": f"order_mock_{uuid.uuid4().hex[:10]}",
                "amount": amount_in_paise,
                "currency": "INR"
            }
        else:
            try:
                # Run the synchronous SDK request in a background thread to prevent blocking the event loop
                razorpay_order = await asyncio.to_thread(
                    razorpay_client.order.create, 
                    data=order_data
                )
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to create Razorpay order: {str(e)}"
                )
            
        donation = Donation(
            donor_id=donor_id,
            amount=amount,
            currency="INR",
            purpose=purpose,
            status="pending",
            razorpay_order_id=razorpay_order["id"]
        )
        
        db.add(donation)
        await db.commit()
        await db.refresh(donation)
        return donation

    @staticmethod
    async def verify_donation_payment(
        db: AsyncSession, 
        razorpay_order_id: str, 
        razorpay_payment_id: str, 
        razorpay_signature: str
    ) -> Donation:
        """
        Verifies the signature of the Razorpay payment and updates the record status.
        """
        result = await db.execute(
            select(Donation).where(Donation.razorpay_order_id == razorpay_order_id)
        )
        donation = result.scalars().first()
        if not donation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Donation record not found for the given order ID"
            )
            
        params = {
            "razorpay_order_id": razorpay_order_id,
            "razorpay_payment_id": razorpay_payment_id,
            "razorpay_signature": razorpay_signature
        }
        
        if settings.RAZORPAY_KEY_ID == "your_razorpay_key_id" or not settings.RAZORPAY_KEY_ID:
            # Simulate signature verification success
            pass
        else:
            try:
                # Run signature verification in a background thread
                await asyncio.to_thread(
                    razorpay_client.utility.verify_payment_signature,
                    params
                )
            except Exception as e:
                donation.status = "failed"
                await db.commit()
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Payment verification failed: Invalid signature"
                )
            
        donation.status = "completed"
        donation.razorpay_payment_id = razorpay_payment_id
        donation.razorpay_signature = razorpay_signature
        await db.commit()
        await db.refresh(donation)
        return donation

    @staticmethod
    async def get_user_donations(db: AsyncSession, donor_id: uuid.UUID):
        """
        Retrieves the payment history for a specific donor.
        """
        result = await db.execute(
            select(Donation)
            .where(Donation.donor_id == donor_id)
            .order_by(Donation.created_at.desc())
        )
        return result.scalars().all()
