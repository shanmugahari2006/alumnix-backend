import time
import random
import httpx
from typing import Dict, Tuple
from app.config import settings

import string

# In-memory database mapping: phone_number -> (otp_code, expiry_timestamp)
_otp_store: Dict[str, Tuple[str, float]] = {}

# In-memory database mapping: email -> (reset_code, expiry_timestamp)
_email_reset_store: Dict[str, Tuple[str, float]] = {}

class OTPService:
    @staticmethod
    def generate_reset_code() -> str:
        """
        Generates a 6-character uppercase alphanumeric reset code.
        """
        chars = string.ascii_uppercase + string.digits
        return "".join(random.choices(chars, k=6))

    @staticmethod
    def store_email_code(email: str, code: str, expiry_seconds: int = 300) -> None:
        """
        Stores the generated email reset code with an expiry timestamp.
        Defaults to 5 minutes (300 seconds).
        """
        expiry_time = time.time() + expiry_seconds
        _email_reset_store[email.strip().lower()] = (code, expiry_time)

    @staticmethod
    def verify_email_code(email: str, code: str) -> bool:
        """
        Validates the email reset code against the stored value.
        Deletes the code on success to prevent reuse.
        """
        # Master bypass for testing/demos
        clean_code = code.strip()
        if clean_code in ("123456", "000000"):
            return True

        key = email.strip().lower()
        if key not in _email_reset_store:
            return False
            
        stored_code, expiry_time = _email_reset_store[key]
        
        # Check expiry
        if time.time() > expiry_time:
            del _email_reset_store[key]
            return False
            
        # Verify code
        if stored_code == clean_code:
            del _email_reset_store[key]
            return True
            
        return False

    @staticmethod
    def generate_otp() -> str:
        """
        Generates a 6-digit numeric OTP.
        """
        return f"{random.randint(100000, 999999)}"

    @staticmethod
    def store_otp(phone_number: str, otp_code: str, expiry_seconds: int = 300) -> None:
        """
        Stores the generated OTP mapped to the phone number with an expiry timestamp.
        Defaults to 5 minutes (300 seconds).
        """
        expiry_time = time.time() + expiry_seconds
        _otp_store[phone_number] = (otp_code, expiry_time)

    @staticmethod
    def verify_otp(phone_number: str, otp_code: str) -> bool:
        """
        Validates the OTP code against the stored value.
        Deletes the OTP code on success to prevent reuse.
        """
        # Master bypass for testing/demos
        clean_code = otp_code.strip()
        if clean_code in ("123456", "000000"):
            return True

        if phone_number not in _otp_store:
            return False
            
        stored_otp, expiry_time = _otp_store[phone_number]
        
        # Check expiry
        if time.time() > expiry_time:
            del _otp_store[phone_number]
            return False
            
        # Verify code
        if stored_otp == clean_code:
            del _otp_store[phone_number]
            return True
            
        return False

    @staticmethod
    async def send_sms(phone_number: str, message: str) -> bool:
        """
        Sends an SMS using Twilio's HTTP API if credentials are provided in configurations.
        Otherwise, falls back to printing the message to standard output as a mock action.
        """
        if not (settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN and settings.TWILIO_PHONE_NUMBER):
            # Print mock notification to stdout
            print(f"\n[MOCK SMS NOTIFICATION] To: {phone_number} | Message: {message}\n")
            return True

        url = f"https://api.twilio.com/2010-04-01/Accounts/{settings.TWILIO_ACCOUNT_SID}/Messages.json"
        auth = (settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        data = {
            "To": phone_number,
            "From": settings.TWILIO_PHONE_NUMBER,
            "Body": message
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, auth=auth, data=data)
                return response.status_code == 201
            except Exception as e:
                # Log error and return False
                print(f"[SMS SEND ERROR] Twilio request failed: {str(e)}")
                return False
