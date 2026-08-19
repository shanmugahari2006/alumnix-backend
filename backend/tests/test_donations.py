import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock
import razorpay
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.donation import Donation

@pytest.mark.asyncio
async def test_create_order(client: AsyncClient, db_session: AsyncSession):
    with patch("app.services.payment_service.razorpay_client") as mock_razorpay:
        # Mock order.create call
        mock_razorpay.order.create.return_value = {
            "id": "order_test_12345",
            "amount": 50000,
            "currency": "INR",
            "receipt": "rcpt_123"
        }
        
        response = await client.post(
            "/api/v1/donations/create-order",
            json={"amount": 500.0, "purpose": "Scholarship"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["order_id"] == "order_test_12345"
        assert data["amount"] == 500.0
        assert data["currency"] == "INR"
        assert "key_id" in data
        
        # Verify it was inserted in the database in pending state
        result = await db_session.execute(
            select(Donation).where(Donation.razorpay_order_id == "order_test_12345")
        )
        donation = result.scalars().first()
        assert donation is not None
        assert donation.amount == 500.0
        assert donation.purpose == "Scholarship"
        assert donation.status == "pending"

@pytest.mark.asyncio
async def test_verify_payment_success(client: AsyncClient, db_session: AsyncSession, test_user):
    # Insert a pending donation first
    donation = Donation(
        donor_id=test_user.id,
        amount=250.0,
        currency="INR",
        purpose="Infrastructure",
        status="pending",
        razorpay_order_id="order_to_verify"
    )
    db_session.add(donation)
    await db_session.commit()
    
    with patch("app.services.payment_service.razorpay_client") as mock_razorpay:
        # verify_payment_signature completes silently on success
        mock_razorpay.utility.verify_payment_signature.return_value = True
        
        payload = {
            "razorpay_order_id": "order_to_verify",
            "razorpay_payment_id": "pay_test_987",
            "razorpay_signature": "signature_test_abc"
        }
        response = await client.post("/api/v1/donations/verify", json=payload)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        
        # Re-fetch donation to verify updated status
        await db_session.refresh(donation)
        assert donation.status == "completed"
        assert donation.razorpay_payment_id == "pay_test_987"
        assert donation.razorpay_signature == "signature_test_abc"

@pytest.mark.asyncio
async def test_verify_payment_failure(client: AsyncClient, db_session: AsyncSession, test_user):
    # Insert a pending donation first
    donation = Donation(
        donor_id=test_user.id,
        amount=100.0,
        currency="INR",
        purpose="Labs",
        status="pending",
        razorpay_order_id="order_to_fail"
    )
    db_session.add(donation)
    await db_session.commit()
    
    with patch("app.services.payment_service.razorpay_client") as mock_razorpay:
        # verify_payment_signature raises error on invalid signature
        mock_razorpay.utility.verify_payment_signature.side_effect = razorpay.errors.SignatureVerificationError("Signature mismatch")
        
        payload = {
            "razorpay_order_id": "order_to_fail",
            "razorpay_payment_id": "pay_failed_987",
            "razorpay_signature": "signature_invalid"
        }
        response = await client.post("/api/v1/donations/verify", json=payload)
        
        assert response.status_code == 400
        assert "Invalid signature" in response.json()["detail"]
        
        # Re-fetch donation to verify status updated to failed
        await db_session.refresh(donation)
        assert donation.status == "failed"

@pytest.mark.asyncio
async def test_get_my_donations(client: AsyncClient, db_session: AsyncSession, test_user):
    # Insert some donations
    d1 = Donation(
        donor_id=test_user.id,
        amount=300.0,
        purpose="Scholarship",
        status="completed",
        razorpay_order_id="order_1"
    )
    d2 = Donation(
        donor_id=test_user.id,
        amount=400.0,
        purpose="Labs",
        status="pending",
        razorpay_order_id="order_2"
    )
    db_session.add_all([d1, d2])
    await db_session.commit()
    
    response = await client.get("/api/v1/donations/my-donations")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 2
    # Verify order of response (descending by created_at)
    assert data[0]["razorpay_order_id"] == "order_2"
    assert data[1]["razorpay_order_id"] == "order_1"
