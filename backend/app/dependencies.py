from typing import List
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.database import get_db
from app.models.user import User
from app.utils.security import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token)
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except ValueError:
        raise credentials_exception

    import uuid
    from app.models import Faculty, Alumni, UserRole

    user_uuid = None
    try:
        user_uuid = uuid.UUID(email)
    except ValueError:
        pass

    query = select(User).where(
        (User.email == email) | (User.phone_number == email)
    )
    if user_uuid:
        query = query.or_(User.id == user_uuid)

    result = await db.execute(query)
    user = result.scalars().first()
    if user is None:
        raise credentials_exception
        
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user account"
        )
        
    # Verify moderation approval based on role
    if user.role == UserRole.alumni:
        a_res = await db.execute(select(Alumni).where(Alumni.id == user.id))
        alumni = a_res.scalars().first()
        if alumni and not alumni.is_approved:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Alumni account pending moderation approval"
            )
    elif user.role == UserRole.faculty:
        f_res = await db.execute(select(Faculty).where(Faculty.user_id == user.id))
        faculty = f_res.scalars().first()
        if faculty and not faculty.is_approved:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Faculty account pending moderation approval"
            )
    return user

def require_role(allowed_roles: List[str]):
    def dependency(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permission denied: Insufficient privileges"
            )
        return current_user
    return dependency
