from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database import get_db
from app.schemas.auth import PhoneOTPRequest, PhoneOTPVerify, TokenResponse
from app.services.otp_service import OTPService
from app.models.user import User, AuthProvider, UserRole, AuthProviderType
from app.utils.security import create_access_token, create_refresh_token

router = APIRouter()

@router.post("/phone/send-otp")
async def send_otp(payload: PhoneOTPRequest):
    """
    Generate and send a 6-digit verification OTP code to the requested phone number.
    Stores the generated code in-memory with a 5-minute expiry.
    """
    phone = payload.phone_number.strip()
    if not phone.startswith("+") or len(phone) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number must be in E.164 format (e.g. +919876543210)"
        )
        
    otp_code = OTPService.generate_otp()
    OTPService.store_otp(phone, otp_code)
    
    sms_message = f"Your AlumniConnect verification OTP is: {otp_code}. Valid for 5 minutes."
    sent = await OTPService.send_sms(phone, sms_message)
    
    if not sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send SMS OTP. Please try again later."
        )
        
    return {"status": "success", "message": "OTP sent successfully"}

@router.post("/phone/verify-otp", response_model=TokenResponse)
async def verify_otp(payload: PhoneOTPVerify, db: AsyncSession = Depends(get_db)):
    """
    Verify the OTP code received by the user.
    If valid, logs the user in or registers a new account linked to the phone provider.
    """
    phone = payload.phone_number.strip()
    otp_code = payload.otp_code.strip()
    
    # 1. Validate the OTP code
    valid = OTPService.verify_otp(phone, otp_code)
    if not valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP code"
        )
        
    # 2. Check for existing User by phone number
    user_query = select(User).where(User.phone_number == phone)
    res = await db.execute(user_query)
    user = res.scalars().first()
    
    if user:
        # User exists, check if AuthProvider is linked
        provider_query = select(AuthProvider).where(
            AuthProvider.user_id == user.id,
            AuthProvider.provider == AuthProviderType.phone
        )
        p_res = await db.execute(provider_query)
        auth_provider = p_res.scalars().first()
        
        if not auth_provider:
            # Link the phone AuthProvider
            new_provider = AuthProvider(
                user_id=user.id,
                provider=AuthProviderType.phone,
                provider_user_id=phone
            )
            db.add(new_provider)
            await db.commit()
    else:
        # Create a new User
        user = User(
            phone_number=phone,
            full_name=f"User {phone}",
            role=UserRole.student,  # Defaults to student role
            is_active=True
        )
        db.add(user)
        await db.flush()  # Populate user.id for relationship link
        
        # Create and link AuthProvider
        new_provider = AuthProvider(
            user_id=user.id,
            provider=AuthProviderType.phone,
            provider_user_id=phone
        )
        db.add(new_provider)
        await db.commit()
        await db.refresh(user)

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user account"
        )
        
    # 3. Issue JWT access and refresh tokens
    access_token = create_access_token(data={"sub": user.email or str(user.id), "role": user.role.value})
    refresh_token = create_refresh_token(data={"sub": user.email or str(user.id), "role": user.role.value})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )
