import os
import re
import urllib.parse
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    PYTHONPATH: str = "."
    DATABASE_URL: str
    
    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def process_database_url(cls, v: str) -> str:
        if not isinstance(v, str):
            return v
        
        # If it is the Supabase direct URL that has parsing/IPv6 issues:
        # e.g., postgresql+asyncpg://postgres:Alumnix1234@@@db.tnmtkvpsgsxsofdeuqna.supabase.co:5432/postgres
        match = re.match(
            r"postgresql\+asyncpg://([^:]+):(.*)@db\.([a-z0-9]+)\.supabase\.co:5432/(.+)", 
            v
        )
        if match:
            username = match.group(1)
            raw_password = match.group(2)
            project_ref = match.group(3)
            dbname = match.group(4)
            
            # URL-encode the password
            encoded_password = urllib.parse.quote_plus(raw_password)
            
            # Change username and host to use the IPv4 connection pooler in Tokyo (ap-northeast-1)
            pooler_username = f"{username}.{project_ref}"
            pooler_host = f"aws-0-ap-northeast-1.pooler.supabase.com"
            
            new_url = f"postgresql+asyncpg://{pooler_username}:{encoded_password}@{pooler_host}:5432/{dbname}"
            return new_url
            
        return v
        
    JWT_SECRET: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 365
    RAZORPAY_KEY_ID: str
    RAZORPAY_KEY_SECRET: str
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_PHONE_NUMBER: str = ""
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = "noreply@alumniconnect.com"
    SUPABASE_URL: str
    SUPABASE_KEY: str

settings = Settings()

