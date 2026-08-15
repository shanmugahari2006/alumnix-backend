import smtplib
from email.mime.text import MIMEText
from app.config import settings

class EmailService:
    @staticmethod
    def send_reset_email(to_email: str, code: str) -> bool:
        """
        Sends a password reset code to the user's email address.
        Falls back to printing a mock email to standard output if SMTP settings are not configured.
        """
        subject = "AlumniConnect - Password Reset Request"
        body = (
            f"Hello,\n\n"
            f"We received a request to reset the password for your AlumniConnect account.\n"
            f"Your temporary reset code is: {code}\n\n"
            f"This code will expire in 5 minutes. If you did not make this request, "
            f"please ignore this email.\n\n"
            f"Best regards,\n"
            f"AlumniConnect Team"
        )

        # Fallback to console logs if SMTP host is not set
        if not settings.SMTP_HOST:
            print(f"\n[MOCK EMAIL NOTIFICATION] To: {to_email} | Subject: {subject} | Body: {code}\n")
            return True

        msg = MIMEText(body)
        msg["Subject"] = subject
        msg["From"] = settings.SMTP_FROM
        msg["To"] = to_email

        try:
            # Connect to SMTP server
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                server.ehlo()
                # Start TLS if port is standard 587
                if settings.SMTP_PORT == 587:
                    server.starttls()
                    server.ehlo()
                
                # Login if user credentials are provided
                if settings.SMTP_USER and settings.SMTP_PASSWORD:
                    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                
                # Send email
                server.sendmail(settings.SMTP_FROM, [to_email], msg.as_string())
            return True
        except Exception as e:
            print(f"[EMAIL SEND ERROR] SMTP request failed: {str(e)}")
            return False
