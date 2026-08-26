import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.device_token import DeviceToken
from app.config import settings

logger = logging.getLogger("app.notifications")

# Lazy Firebase Admin initialization
_firebase_initialized = False

def _init_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return True
    
    cred_path = settings.FIREBASE_CREDENTIALS_PATH
    if not cred_path:
        logger.warning("FIREBASE_CREDENTIALS_PATH is not set. Real push notifications are disabled; running in mock fallback mode.")
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials
        
        # Check if already initialized by another module
        try:
            firebase_admin.get_app()
            _firebase_initialized = True
            return True
        except ValueError:
            pass

        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK successfully initialized.")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}. Running in mock fallback mode.")
        return False


class NotificationService:
    @staticmethod
    async def register_device_token(db: AsyncSession, user_id: str, token: str) -> DeviceToken:
        """
        Store or update an FCM token for a user.
        """
        # Check if token already exists for this user
        query = select(DeviceToken).where(DeviceToken.user_id == user_id, DeviceToken.token == token)
        result = await db.execute(query)
        existing = result.scalars().first()
        if existing:
            return existing

        # Token might belong to another user; remove it first to avoid duplicate conflicts
        cleanup_query = select(DeviceToken).where(DeviceToken.token == token)
        cleanup_res = await db.execute(cleanup_query)
        stale_tokens = cleanup_res.scalars().all()
        for stale in stale_tokens:
            await db.delete(stale)
        
        new_token = DeviceToken(user_id=user_id, token=token)
        db.add(new_token)
        await db.commit()
        await db.refresh(new_token)
        return new_token

    @staticmethod
    async def unregister_device_token(db: AsyncSession, user_id: str, token: str) -> None:
        """
        Remove a device token.
        """
        query = select(DeviceToken).where(DeviceToken.user_id == user_id, DeviceToken.token == token)
        result = await db.execute(query)
        tokens = result.scalars().all()
        for t in tokens:
            await db.delete(t)
        await db.commit()

    @staticmethod
    async def send_push_to_user(
        db: AsyncSession,
        user_id: str,
        title: str,
        body: str,
        data: dict = None
    ) -> None:
        """
        Resolve registered FCM tokens for a user, and attempt to send a push notification.
        Fallback to safe console logs if Firebase is unconfigured.
        """
        query = select(DeviceToken.token).where(DeviceToken.user_id == user_id)
        result = await db.execute(query)
        tokens = result.scalars().all()

        if not tokens:
            # Print mock notification to logs anyway so it shows up in Railway during testing
            print(f"\n[MOCK FCM NOTIFICATION (No Token Registered)] To User: {user_id} | Title: '{title}' | Body: '{body}' | Data: {data}\n")
            return

        # Prepare strings in data payload (FCM data fields must be string-only mapping)
        fcm_data = {}
        if data:
            for k, v in data.items():
                fcm_data[str(k)] = str(v)

        firebase_ready = _init_firebase()
        
        if firebase_ready:
            try:
                from firebase_admin import messaging
                for token in tokens:
                    message = messaging.Message(
                        notification=messaging.Notification(
                            title=title,
                            body=body,
                        ),
                        data=fcm_data,
                        token=token,
                    )
                    messaging.send(message)
                logger.info(f"FCM push notification dispatched to user {user_id} ({len(tokens)} tokens).")
                print(f"[REAL FCM PUSH SENT] User: {user_id} | Title: '{title}'")
                return
            except Exception as e:
                logger.error(f"FCM push delivery failed: {e}. Falling back to mock log.")

        # Fallback Mock logging
        for token in tokens:
            print(f"\n[MOCK FCM NOTIFICATION] Token: {token[:12]}... | To User: {user_id} | Title: '{title}' | Body: '{body}' | Data: {fcm_data}\n")

    @classmethod
    async def broadcast_event_created(cls, event_id: str, title: str, creator_name: str, creator_id: str) -> None:
        """
        Broadcast a new event notification to all active users except the creator.
        """
        from app.database import SessionLocal
        from app.models.user import User
        
        async with SessionLocal() as db:
            query = select(User.id).where(User.is_active == True, User.id != creator_id)
            res = await db.execute(query)
            user_ids = res.scalars().all()
            
            for uid in user_ids:
                await cls.send_push_to_user(
                    db,
                    str(uid),
                    title="New Campus Event! 📅",
                    body=f"{creator_name} created event '{title}'. Register now!",
                    data={
                        "event_type": "event_created",
                        "event_id": event_id,
                    }
                )

    @classmethod
    async def broadcast_story_created(cls, story_id: str, title: str, author_name: str, author_id: str) -> None:
        """
        Broadcast a new story/post notification to all active users except the author.
        """
        from app.database import SessionLocal
        from app.models.user import User
        
        async with SessionLocal() as db:
            query = select(User.id).where(User.is_active == True, User.id != author_id)
            res = await db.execute(query)
            user_ids = res.scalars().all()
            
            for uid in user_ids:
                await cls.send_push_to_user(
                    db,
                    str(uid),
                    title="New Post Uploaded! ✍️",
                    body=f"{author_name} shared a new story: '{title}'. Check it out!",
                    data={
                        "event_type": "story_created",
                        "story_id": story_id,
                    }
                )

    @classmethod
    async def send_message_notification(cls, recipient_id: str, sender_name: str, message_content: str, conversation_id: str) -> None:
        """
        Send a direct message notification to the recipient user.
        """
        from app.database import SessionLocal
        
        async with SessionLocal() as db:
            await cls.send_push_to_user(
                db,
                recipient_id,
                title=f"New Message from {sender_name} 💬",
                body=message_content if len(message_content) < 60 else f"{message_content[:60]}...",
                data={
                    "event_type": "new_message",
                    "conversation_id": conversation_id,
                }
            )
