import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.database import get_db
from app.models import User, Student, Alumni, Faculty, CollegeRecord, UserRole
from app.schemas.auth import (
    UserLogin, TokenResponse, RefreshTokenRequest,
    StudentUserResponse, AlumniUserResponse, UserResponse, StudentProfileResponse, AlumniProfileResponse,
    FacultyProfileResponse, UserMeResponse, ForgotPasswordRequest, ResetPasswordRequest,
    VerifyUSNRequest, VerifyUSNResponse, SendSocialOTPRequest, VerifySocialOTPRequest,
    VerifySocialOTPResponse, SetupPasswordRequest
)
from app.schemas.faculty import FacultyRegister, FacultyResponse
from app.utils.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.dependencies import get_current_user, require_role
from app.services.otp_service import OTPService
from app.services.email_service import EmailService
from sqlalchemy.orm import selectinload

router = APIRouter()

@router.post("/register/verify-usn", response_model=VerifyUSNResponse)
async def verify_usn(payload: VerifyUSNRequest, db: AsyncSession = Depends(get_db)):
    """
    Check if the USN exists in the official college registry and role matches.
    Ensures that this USN has not already been registered in the system.
    """
    usn = payload.usn.strip().upper()
    
    # Check if already registered
    s_exists = await db.execute(select(Student).where(Student.usn == usn))
    a_exists = await db.execute(select(Alumni).where(Alumni.usn == usn))
    if s_exists.scalars().first() or a_exists.scalars().first():
        raise HTTPException(status_code=400, detail="USN already registered")
        
    # Check registry records
    reg_res = await db.execute(select(CollegeRecord).where(
        CollegeRecord.usn == usn,
        CollegeRecord.role == payload.role
    ))
    record = reg_res.scalars().first()
    if not record:
        raise HTTPException(
            status_code=400,
            detail=f"USN not found in registry for role: {payload.role.value}"
        )
        
    return VerifyUSNResponse(full_name=record.full_name)

@router.post("/register/send-otp")
async def send_social_otp(payload: SendSocialOTPRequest, db: AsyncSession = Depends(get_db)):
    """
    Generates and sends an OTP verification code to the user's pre-verified email
    or phone number from the college registry record.
    """
    usn = payload.usn.strip().upper()
    channel = payload.channel.strip().lower()
    
    if channel not in ["email", "phone"]:
        raise HTTPException(status_code=400, detail="Channel must be 'email' or 'phone'")
        
    # Retrieve registry record
    reg_res = await db.execute(select(CollegeRecord).where(CollegeRecord.usn == usn))
    record = reg_res.scalars().first()
    if not record:
        raise HTTPException(status_code=400, detail="USN not found in registry")
        
    otp_code = OTPService.generate_otp()
    
    if channel == "email":
        target = record.email
        OTPService.store_email_code(target, otp_code)
        EmailService.send_reset_email(target, otp_code)
    else:
        target = record.phone_number
        OTPService.store_otp(target, otp_code)
        await OTPService.send_sms(target, f"Your AlumniConnect verification OTP is: {otp_code}. Valid for 5 minutes.")
        
    return {"status": "success", "message": f"Verification OTP sent to your registered {channel}"}

@router.post("/register/verify-otp", response_model=VerifySocialOTPResponse)
async def verify_social_otp(payload: VerifySocialOTPRequest, db: AsyncSession = Depends(get_db)):
    """
    Verifies the OTP code. Returns a signed temporary verification token.
    """
    usn = payload.usn.strip().upper()
    channel = payload.channel.strip().lower()
    otp_code = payload.otp_code.strip()
    
    if channel not in ["email", "phone"]:
        raise HTTPException(status_code=400, detail="Channel must be 'email' or 'phone'")
        
    reg_res = await db.execute(select(CollegeRecord).where(CollegeRecord.usn == usn))
    record = reg_res.scalars().first()
    if not record:
        raise HTTPException(status_code=400, detail="USN not found in registry")
        
    if channel == "email":
        valid = OTPService.verify_email_code(record.email, otp_code)
    else:
        valid = OTPService.verify_otp(record.phone_number, otp_code)
        
    if not valid:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")
        
    # Generate temporary verification token (10 minutes)
    verification_token = create_access_token(
        data={"sub": usn, "type": "verification_token"}
    )
    return VerifySocialOTPResponse(verification_token=verification_token)

@router.post("/register/setup-password", response_model=TokenResponse)
async def setup_password(payload: SetupPasswordRequest, db: AsyncSession = Depends(get_db)):
    """
    Uses the verification token to finalise account setup by creating a password.
    Autofills profile from registry database.
    """
    try:
        claims = decode_token(payload.verification_token)
        if claims.get("type") != "verification_token":
            raise HTTPException(status_code=401, detail="Invalid verification token type")
        usn = claims.get("sub")
        if not usn:
            raise HTTPException(status_code=401, detail="Invalid verification token claims")
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid or expired verification token")
        
    # Get registry record
    reg_res = await db.execute(select(CollegeRecord).where(CollegeRecord.usn == usn))
    record = reg_res.scalars().first()
    if not record:
        raise HTTPException(status_code=400, detail="Registry record not found")
        
    # Check duplicate account
    s_exists = await db.execute(select(Student).where(Student.usn == usn))
    a_exists = await db.execute(select(Alumni).where(Alumni.usn == usn))
    if s_exists.scalars().first() or a_exists.scalars().first():
        raise HTTPException(status_code=400, detail="USN already registered")
        
    if record.email:
        e_res = await db.execute(select(User).where(User.email == record.email))
        if e_res.scalars().first():
            raise HTTPException(status_code=400, detail="Email already registered")
            
    if record.phone_number:
        p_res = await db.execute(select(User).where(User.phone_number == record.phone_number))
        if p_res.scalars().first():
            raise HTTPException(status_code=400, detail="Phone number already registered")
            
    # Create base User
    new_user = User(
        email=record.email,
        phone_number=record.phone_number,
        hashed_password=hash_password(payload.password),
        full_name=record.full_name,
        role=record.role,
        is_active=True
    )
    db.add(new_user)
    await db.flush()
    
    # Create Profile
    if record.role == UserRole.student:
        profile = Student(
            id=new_user.id,
            usn=usn,
            branch=record.branch,
            graduation_year=record.graduation_year
        )
    else:
        profile = Alumni(
            id=new_user.id,
            usn=usn,
            graduation_year=record.graduation_year,
            branch=record.branch,
            is_approved=True  # Auto-approved since verified on signup
        )
    db.add(profile)
    await db.commit()
    
    access_token = create_access_token(data={"sub": new_user.email or str(new_user.id), "role": new_user.role.value})
    refresh_token = create_refresh_token(data={"sub": new_user.email or str(new_user.id), "role": new_user.role.value})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )

@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    """
    Validate credentials and generate JWT tokens.
    Checks status validation and moderation approval flags based on role.
    """
    query = select(User).where(
        (User.email == payload.email) | (User.phone_number == payload.email)
    )
    result = await db.execute(query)
    user = result.scalars().first()
    
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email/phone or password")
        
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive account")
        
    # Check approval moderation based on role
    if user.role == UserRole.alumni:
        alumni_res = await db.execute(select(Alumni).where(Alumni.id == user.id))
        alumni = alumni_res.scalars().first()
        if alumni and not alumni.is_approved:
            raise HTTPException(status_code=400, detail="Alumni account pending moderation approval")
            
    elif user.role == UserRole.faculty:
        faculty_res = await db.execute(select(Faculty).where(Faculty.user_id == user.id))
        faculty = faculty_res.scalars().first()
        if faculty and not faculty.is_approved:
            raise HTTPException(status_code=400, detail="Faculty account pending moderation approval")
            
    access_token = create_access_token(data={"sub": user.email or str(user.id), "role": user.role.value})
    refresh_token = create_refresh_token(data={"sub": user.email or str(user.id), "role": user.role.value})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """
    Refresh access token.
    """
    try:
        claims = decode_token(payload.refresh_token)
        if claims.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        sub = claims.get("sub")
        if not sub:
            raise HTTPException(status_code=401, detail="Invalid token claims")
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
        
    # Resolve user by ID or email/phone
    query = select(User).where(
        (User.email == sub) | (User.phone_number == sub)
    )
    try:
        user_uuid = uuid.UUID(sub)
        query = query.or_(User.id == user_uuid)
    except ValueError:
        pass
        
    result = await db.execute(query)
    user = result.scalars().first()
    
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Invalid user or inactive account")
        
    new_access_token = create_access_token(data={"sub": user.email or str(user.id), "role": user.role.value})
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=payload.refresh_token,
        token_type="bearer"
    )

@router.post("/register/faculty", response_model=FacultyResponse, status_code=status.HTTP_201_CREATED)
async def register_faculty(payload: FacultyRegister, db: AsyncSession = Depends(get_db)):
    """
    Register a new faculty member, pending admin approval.
    """
    if payload.email:
        email_res = await db.execute(select(User).where(User.email == payload.email))
        if email_res.scalars().first():
            raise HTTPException(status_code=400, detail="Email already registered")
            
    if payload.phone_number:
        phone_res = await db.execute(select(User).where(User.phone_number == payload.phone_number))
        if phone_res.scalars().first():
            raise HTTPException(status_code=400, detail="Phone number already registered")
            
    emp_res = await db.execute(select(Faculty).where(Faculty.employee_id == payload.employee_id))
    if emp_res.scalars().first():
        raise HTTPException(status_code=400, detail="Employee ID already registered")
        
    # Create User
    new_user = User(
        email=payload.email,
        phone_number=payload.phone_number,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role=UserRole.faculty,
        is_active=True
    )
    db.add(new_user)
    await db.flush()
    
    # Create Faculty (marked unapproved)
    new_faculty = Faculty(
        user_id=new_user.id,
        employee_id=payload.employee_id,
        department=payload.department,
        designation=payload.designation,
        is_approved=False
    )
    db.add(new_faculty)
    await db.commit()
    await db.refresh(new_user)
    await db.refresh(new_faculty)
    
    return FacultyResponse(
        user=UserResponse.model_validate(new_user),
        faculty=FacultyProfileResponse.model_validate(new_faculty)
    )


@router.get("/me", response_model=UserMeResponse)
async def get_me(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """
    Return current logged-in user profile details along with profile data.
    """
    student_profile = None
    alumni_profile = None
    faculty_profile = None

    if current_user.role == "student":
        res = await db.execute(select(Student).where(Student.id == current_user.id))
        student_profile = res.scalars().first()
    elif current_user.role == "alumni":
        res = await db.execute(select(Alumni).where(Alumni.id == current_user.id))
        alumni_profile = res.scalars().first()
    elif current_user.role == "faculty":
        res = await db.execute(select(Faculty).where(Faculty.user_id == current_user.id))
        faculty_profile = res.scalars().first()

    return UserMeResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        role=current_user.role,
        is_active=current_user.is_active,
        student_profile=StudentProfileResponse.model_validate(student_profile) if student_profile else None,
        alumni_profile=AlumniProfileResponse.model_validate(alumni_profile) if alumni_profile else None,
        faculty_profile=FacultyProfileResponse.model_validate(faculty_profile) if faculty_profile else None
    )

@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    """
    Initiates password recovery. Generates and sends a reset code/OTP to the registered
    email or phone number.
    """
    if payload.email:
        email = payload.email.strip().lower()
        res = await db.execute(select(User).where(User.email == email))
        user = res.scalars().first()
        if not user:
            # Return success even if user not found to prevent user enumeration
            return {"status": "success", "message": "Recovery code sent if account exists"}
            
        code = OTPService.generate_reset_code()
        OTPService.store_email_code(email, code)
        EmailService.send_reset_email(email, code)
        return {"status": "success", "message": "Recovery code sent successfully"}
        
    elif payload.phone_number:
        phone = payload.phone_number.strip()
        res = await db.execute(select(User).where(User.phone_number == phone))
        user = res.scalars().first()
        if not user:
            return {"status": "success", "message": "Recovery code sent if account exists"}
            
        otp = OTPService.generate_otp()
        OTPService.store_otp(phone, otp)
        await OTPService.send_sms(phone, f"Your AlumniConnect password reset OTP is: {otp}. Valid for 5 minutes.")
        return {"status": "success", "message": "Recovery OTP sent successfully"}

@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    """
    Resets the password after verifying the code/OTP.
    """
    if payload.email:
        email = payload.email.strip().lower()
        valid = OTPService.verify_email_code(email, payload.code)
        if not valid:
            raise HTTPException(status_code=400, detail="Invalid or expired reset code")
            
        res = await db.execute(select(User).where(User.email == email))
        user = res.scalars().first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        user.hashed_password = hash_password(payload.new_password)
        await db.commit()
        return {"status": "success", "message": "Password reset successfully"}
        
    elif payload.phone_number:
        phone = payload.phone_number.strip()
        valid = OTPService.verify_otp(phone, payload.code)
        if not valid:
            raise HTTPException(status_code=400, detail="Invalid or expired OTP code")
            
        res = await db.execute(select(User).where(User.phone_number == phone))
        user = res.scalars().first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        user.hashed_password = hash_password(payload.new_password)
        await db.commit()
        return {"status": "success", "message": "Password reset successfully"}

@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(current_user: User = Depends(get_current_user)):
    """
    Log out the user. The client should discard the local JWT tokens.
    """
    return {"status": "success", "message": "Successfully logged out"}

@router.patch("/faculty/{faculty_id}/approve", response_model=FacultyResponse)
async def approve_faculty(
    faculty_id: uuid.UUID,
    admin_user: User = Depends(require_role(["admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Allows admins to verify and approve faculty registrations.
    """
    res = await db.execute(
        select(Faculty).where(Faculty.id == faculty_id).options(selectinload(Faculty.user))
    )
    faculty = res.scalars().first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty profile not found")
        
    faculty.is_approved = True
    await db.commit()
    await db.refresh(faculty)
    
    return FacultyResponse(
        user=UserResponse.model_validate(faculty.user),
        faculty=FacultyProfileResponse.model_validate(faculty)
    )



