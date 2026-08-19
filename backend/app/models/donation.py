import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Float, UUID
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Donation(Base):
    __tablename__ = "donations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    donor_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String, default="INR", nullable=False)
    purpose = Column(String, nullable=False)
    status = Column(String, default="pending", nullable=False)  # pending, completed, failed
    razorpay_order_id = Column(String, index=True, nullable=False)
    razorpay_payment_id = Column(String, nullable=True)
    razorpay_signature = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    donor = relationship("User")
