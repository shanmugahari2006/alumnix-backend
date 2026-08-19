import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class DonationCreate(BaseModel):
    amount: float = Field(..., gt=0, description="Amount in INR")
    purpose: str = Field(..., min_length=1, description="Purpose of the donation (Scholarship, Infrastructure, Labs, etc.)")

class DonationOrderResponse(BaseModel):
    order_id: str
    amount: float
    currency: str
    key_id: str

class DonationVerify(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str

class DonationVerifyResponse(BaseModel):
    status: str
    message: str
    donation_id: uuid.UUID

class DonationResponse(BaseModel):
    id: uuid.UUID
    amount: float
    purpose: str
    status: str
    razorpay_order_id: str
    razorpay_payment_id: Optional[str] = None
    created_at: datetime
    
    model_config = {"from_attributes": True}
