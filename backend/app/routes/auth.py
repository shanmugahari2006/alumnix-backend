from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.database import get_db
from app.models import User, Student, Alumni, Faculty
from app.schemas.auth import (
    StudentRegister, AlumniRegister, UserLogin, TokenResponse, RefreshTokenRequest,
    StudentUserResponse, AlumniUserResponse, UserResponse, StudentProfileResponse, AlumniProfileResponse,
    FacultyProfileResponse, UserMeResponse
)
from app.schemas.faculty import FacultyRegister, FacultyResponse
from app.utils.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.dependencies import get_current_user

router = APIRouter()

@router.post("/register/student", response_model=StudentUserResponse, status_code=status.HTTP_201_CREATED)
async def register_student(payload: StudentRegister, db: AsyncSession = Depends(get_db)):
    """
    Register a new student. 
    
    Creates a base User record and an associated Student record.
    Checks for existing email or roll number to prevent duplicates.
    """
    # Check if email exists
    result = await db.execute(select(User).where(User.email == payload.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    # Check if roll number exists
    result = await db.execute(select(Student).where(Student.roll_number == payload.roll_number))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Roll number already registered")

    # Create User
    new_user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role="student",
        is_active=True
    )
    db.add(new_user)
    await db.flush() # Populate new_user.id for FK reference

    # Create Student
    new_student = Student(
        id=new_user.id,
        roll_number=payload.roll_number,
        branch=payload.branch,
        graduation_year=payload.graduation_year
    )
    db.add(new_student)
    await db.commit()
    await db.refresh(new_user)
    await db.refresh(new_student)

    return StudentUserResponse(
        user=UserResponse.model_validate(new_user),
        student=StudentProfileResponse.model_validate(new_student)
    )

@router.post("/register/alumni", response_model=AlumniUserResponse, status_code=status.HTTP_201_CREATED)
async def register_alumni(payload: AlumniRegister, db: AsyncSession = Depends(get_db)):
    """
    Register a new alumni. 
    
    Creates a base User record and an associated Alumni record.
    Alumni records default to unapproved (is_approved=False).
    """
    # Check if email exists
    result = await db.execute(select(User).where(User.email == payload.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create User
    new_user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role="alumni",
        is_active=True
    )
    db.add(new_user)
    await db.flush() # Populate new_user.id for FK reference

    # Create Alumni
    new_alumni = Alumni(
        id=new_user.id,
        company=payload.company,
        designation=payload.designation,
        graduation_year=payload.graduation_year,
        is_approved=False
    )
    db.add(new_alumni)
    await db.commit()
    await db.refresh(new_user)
    await db.refresh(new_alumni)

    return AlumniUserResponse(
        user=UserResponse.model_validate(new_user),
        alumni=AlumniProfileResponse.model_validate(new_alumni)
    )

@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    """
    Validate credentials and generate JWT tokens.
    
    Checks if credentials match and the account is currently marked active.
    """
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalars().first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
        
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive account")

    access_token = create_access_token(data={"sub": user.email, "role": user.role})
    refresh_token = create_refresh_token(data={"sub": user.email, "role": user.role})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """
    Refresh access token.
    
    Validates the refresh token and returns a new access token while keeping the refresh token.
    """
    try:
        claims = decode_token(payload.refresh_token)
        if claims.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        email = claims.get("sub")
        if not email:
            raise HTTPException(status_code=401, detail="Invalid token claims")
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalars().first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Invalid user or inactive account")

    new_access_token = create_access_token(data={"sub": user.email, "role": user.role})
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=payload.refresh_token,
        token_type="bearer"
    )

@router.post("/register/faculty", response_model=FacultyResponse, status_code=status.HTTP_201_CREATED)
async def register_faculty(payload: FacultyRegister, db: AsyncSession = Depends(get_db)):
    """
    Register a new faculty member.
    
    Creates a User record and an associated Faculty record.
    Checks for existing email or employee ID to prevent duplicates.
    """
    # Check if email exists
    result = await db.execute(select(User).where(User.email == payload.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    # Check if employee ID exists
    result = await db.execute(select(Faculty).where(Faculty.employee_id == payload.employee_id))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Employee ID already registered")

    # Create User
    new_user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role="faculty",
        is_active=True
    )
    db.add(new_user)
    await db.flush() # Populate new_user.id

    # Create Faculty
    new_faculty = Faculty(
        user_id=new_user.id,
        employee_id=payload.employee_id,
        department=payload.department,
        designation=payload.designation
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
