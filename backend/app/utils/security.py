from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import jwt, JWTError
from passlib.context import CryptContext
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.ALGORITHM)

def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.ALGORITHM)

def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError as e:
        raise ValueError("Invalid token") from e

def create_jitsi_token(
    room_name: str,
    user_id: str,
    user_name: str,
    user_email: str
) -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=2)
    nbf = datetime.now(timezone.utc) - timedelta(minutes=5)
    payload = {
        "aud": settings.JITSI_APP_ID,
        "iss": settings.JITSI_APP_ID,
        "sub": settings.JITSI_DOMAIN,
        "room": room_name,
        "exp": expire,
        "nbf": nbf,
        "context": {
            "user": {
                "id": user_id,
                "name": user_name,
                "email": user_email
            }
        }
    }
    return jwt.encode(payload, settings.JITSI_APP_SECRET, algorithm="HS256")
