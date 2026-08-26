import uuid
from datetime import datetime
from typing import List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload, joinedload
from sqlalchemy import or_, and_, func, update

from app.models.user import User, Student, Alumni, UserRole
from app.models.conversation import Conversation, Message
from app.schemas.chat import (
    ChatUserSummary, MessageResponse, ConversationResponse,
    ConversationDetailResponse
)

class ChatService:
    @staticmethod
    async def build_user_summary(db: AsyncSession, user: User) -> ChatUserSummary:
        company = None
        designation = None
        branch = None
        graduation_year = None

        if user.role == UserRole.alumni:
            a_res = await db.execute(select(Alumni).where(Alumni.id == user.id))
            alumni = a_res.scalars().first()
            if alumni:
                company = alumni.company
                designation = alumni.designation
                branch = alumni.branch
                graduation_year = alumni.graduation_year
        elif user.role == UserRole.student:
            s_res = await db.execute(select(Student).where(Student.id == user.id))
            student = s_res.scalars().first()
            if student:
                branch = student.branch
                graduation_year = student.graduation_year

        return ChatUserSummary(
            id=user.id,
            full_name=user.full_name,
            email=user.email,
            role=user.role.value if hasattr(user.role, 'value') else str(user.role),
            avatar_url=user.avatar_url,
            company=company,
            designation=designation,
            branch=branch,
            graduation_year=graduation_year
        )

    @staticmethod
    async def get_or_create_conversation(
        db: AsyncSession,
        current_user_id: uuid.UUID,
        recipient_id: uuid.UUID
    ) -> Conversation:
        if current_user_id == recipient_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot start a conversation with yourself"
            )

        # Check recipient exists
        r_res = await db.execute(select(User).where(User.id == recipient_id))
        recipient = r_res.scalars().first()
        if not recipient:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Recipient user not found"
            )

        u1, u2 = (current_user_id, recipient_id) if current_user_id < recipient_id else (recipient_id, current_user_id)

        query = select(Conversation).where(
            and_(Conversation.user1_id == u1, Conversation.user2_id == u2)
        )
        res = await db.execute(query)
        conversation = res.scalars().first()

        if not conversation:
            conversation = Conversation(
                user1_id=u1,
                user2_id=u2,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(conversation)
            await db.commit()
            await db.refresh(conversation)

        return conversation

    @staticmethod
    async def get_conversation_by_id(
        db: AsyncSession,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> Conversation:
        query = select(Conversation).where(Conversation.id == conversation_id)
        res = await db.execute(query)
        conversation = res.scalars().first()

        if not conversation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found"
            )

        if user_id not in (conversation.user1_id, conversation.user2_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this conversation"
            )

        return conversation

    @staticmethod
    async def list_user_conversations(
        db: AsyncSession,
        current_user: User
    ) -> List[ConversationResponse]:
        query = select(Conversation).where(
            or_(Conversation.user1_id == current_user.id, Conversation.user2_id == current_user.id)
        ).order_by(Conversation.updated_at.desc())

        res = await db.execute(query)
        conversations = res.scalars().all()

        responses = []
        for conv in conversations:
            partner_id = conv.user2_id if conv.user1_id == current_user.id else conv.user1_id
            partner_res = await db.execute(select(User).where(User.id == partner_id))
            partner_user = partner_res.scalars().first()

            if not partner_user:
                continue

            partner_summary = await ChatService.build_user_summary(db, partner_user)

            # Fetch last message
            msg_query = select(Message).where(
                Message.conversation_id == conv.id
            ).order_by(Message.created_at.desc()).limit(1)
            msg_res = await db.execute(msg_query)
            last_msg_model = msg_res.scalars().first()

            last_msg_resp = None
            if last_msg_model:
                sender_res = await db.execute(select(User).where(User.id == last_msg_model.sender_id))
                sender_user = sender_res.scalars().first()
                sender_name = sender_user.full_name if sender_user else "Unknown"
                last_msg_resp = MessageResponse(
                    id=last_msg_model.id,
                    conversation_id=last_msg_model.conversation_id,
                    sender_id=last_msg_model.sender_id,
                    sender_name=sender_name,
                    content=last_msg_model.content,
                    is_read=last_msg_model.is_read,
                    created_at=last_msg_model.created_at
                )

            # Count unread messages sent by partner
            unread_query = select(func.count(Message.id)).where(
                and_(
                    Message.conversation_id == conv.id,
                    Message.sender_id != current_user.id,
                    Message.is_read == False
                )
            )
            unread_res = await db.execute(unread_query)
            unread_count = unread_res.scalar() or 0

            responses.append(ConversationResponse(
                id=conv.id,
                partner=partner_summary,
                last_message=last_msg_resp,
                unread_count=unread_count,
                created_at=conv.created_at,
                updated_at=conv.updated_at
            ))

        return responses

    @staticmethod
    async def get_messages(
        db: AsyncSession,
        conversation_id: uuid.UUID,
        current_user_id: uuid.UUID
    ) -> List[MessageResponse]:
        # Authorize access
        await ChatService.get_conversation_by_id(db, conversation_id, current_user_id)

        query = select(Message, User.full_name).join(
            User, Message.sender_id == User.id
        ).where(
            Message.conversation_id == conversation_id
        ).order_by(Message.created_at.asc())

        res = await db.execute(query)
        results = res.all()

        message_responses = []
        for msg, sender_name in results:
            message_responses.append(MessageResponse(
                id=msg.id,
                conversation_id=msg.conversation_id,
                sender_id=msg.sender_id,
                sender_name=sender_name,
                content=msg.content,
                is_read=msg.is_read,
                created_at=msg.created_at
            ))

        return message_responses

    @staticmethod
    async def save_message(
        db: AsyncSession,
        conversation_id: uuid.UUID,
        sender_id: uuid.UUID,
        content: str
    ) -> MessageResponse:
        content = content.strip()
        if not content:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message content cannot be empty"
            )
        if len(content) > 2000:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message exceeds maximum allowed length (2000 characters)"
            )

        conv = await ChatService.get_conversation_by_id(db, conversation_id, sender_id)

        now = datetime.utcnow()
        message = Message(
            conversation_id=conversation_id,
            sender_id=sender_id,
            content=content,
            is_read=False,
            created_at=now
        )
        db.add(message)
        conv.updated_at = now
        await db.commit()
        await db.refresh(message)

        # Get sender full name
        s_res = await db.execute(select(User).where(User.id == sender_id))
        sender_user = s_res.scalars().first()
        sender_name = sender_user.full_name if sender_user else "Unknown"

        # Trigger Push Notification in background
        import asyncio
        from app.services.notification_service import NotificationService
        recipient_id = conv.user_two_id if conv.user_one_id == sender_id else conv.user_one_id
        asyncio.create_task(
            NotificationService.send_message_notification(
                str(recipient_id),
                sender_name,
                content,
                str(conversation_id)
            )
        )

        return MessageResponse(
            id=message.id,
            conversation_id=message.conversation_id,
            sender_id=message.sender_id,
            sender_name=sender_name,
            content=message.content,
            is_read=message.is_read,
            created_at=message.created_at
        )

    @staticmethod
    async def mark_messages_as_read(
        db: AsyncSession,
        conversation_id: uuid.UUID,
        current_user_id: uuid.UUID
    ) -> int:
        await ChatService.get_conversation_by_id(db, conversation_id, current_user_id)

        stmt = update(Message).where(
            and_(
                Message.conversation_id == conversation_id,
                Message.sender_id != current_user_id,
                Message.is_read == False
            )
        ).values(is_read=True)

        res = await db.execute(stmt)
        await db.commit()
        return res.rowcount

    @staticmethod
    async def get_total_unread_count(
        db: AsyncSession,
        user_id: uuid.UUID
    ) -> int:
        # Find all conversation IDs for user
        conv_query = select(Conversation.id).where(
            or_(Conversation.user1_id == user_id, Conversation.user2_id == user_id)
        )
        conv_res = await db.execute(conv_query)
        conv_ids = conv_res.scalars().all()

        if not conv_ids:
            return 0

        unread_query = select(func.count(Message.id)).where(
            and_(
                Message.conversation_id.in_(conv_ids),
                Message.sender_id != user_id,
                Message.is_read == False
            )
        )
        res = await db.execute(unread_query)
        return res.scalar() or 0

    @staticmethod
    async def search_chat_users(
        db: AsyncSession,
        current_user: User,
        query: Optional[str] = None
    ) -> List[ChatUserSummary]:
        stmt = select(User).where(
            and_(User.id != current_user.id, User.is_active == True)
        )

        if query:
            q = f"%{query.strip()}%"
            stmt = stmt.where(
                or_(
                    User.full_name.ilike(q),
                    User.email.ilike(q)
                )
            )

        res = await db.execute(stmt)
        users = res.scalars().all()

        summaries = []
        for u in users:
            summary = await ChatService.build_user_summary(db, u)
            summaries.append(summary)

        return summaries
