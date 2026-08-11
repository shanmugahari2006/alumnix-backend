import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    PYTHONPATH: str = "."
    DATABASE_URL: str
    JWT_SECRET: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    GOOGLE_CLIENT_ID: str
    LINKEDIN_CLIENT_ID: str
    RAZORPAY_KEY_ID: str
    RAZORPAY_KEY_SECRET: str
    SUPABASE_URL: str
    SUPABASE_KEY: str

settings = Settings()
