import uuid
from typing import List, Optional
from fastapi import (
    APIRouter, Depends, HTTPException, Query, status,
    WebSocket, WebSocketDisconnect
)
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db, SessionLocal
from app.models.user import User
from app.dependencies import get_current_user
from app.utils.security import decode_token
from app.schemas.chat import (
    ConversationResponse, MessageResponse, SendMessageRequest,
    StartConversationRequest, ChatUserSummary, UnreadCountResponse
)
from app.services.chat_service import ChatService
from app.services.websocket_manager import manager
from sqlalchemy.future import select

router = APIRouter()

@router.get("/conversations", response_model=List[ConversationResponse])
async def list_conversations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List all active conversations for the authenticated user with partner details,
    last message, timestamp, and unread counts.
    """
    return await ChatService.list_user_conversations(db, current_user)

@router.post("/conversations", response_model=ConversationResponse)
async def start_conversation(
    payload: StartConversationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Start or retrieve an existing one-to-one conversation with another user.
    """
    conv = await ChatService.get_or_create_conversation(db, current_user.id, payload.recipient_id)
    conversations = await ChatService.list_user_conversations(db, current_user)
    for c in conversations:
        if c.id == conv.id:
            return c

    # Fallback response
    partner_res = await db.execute(select(User).where(User.id == payload.recipient_id))
    partner = partner_res.scalars().first()
    partner_summary = await ChatService.build_user_summary(db, partner)
    return ConversationResponse(
        id=conv.id,
        partner=partner_summary,
        last_message=None,
        unread_count=0,
        created_at=conv.created_at,
        updated_at=conv.updated_at
    )

@router.get("/conversations/{conversation_id}", response_model=ConversationResponse)
async def get_conversation_detail(
    conversation_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get detailed information about a single conversation.
    """
    await ChatService.get_conversation_by_id(db, conversation_id, current_user.id)
    conversations = await ChatService.list_user_conversations(db, current_user)
    for c in conversations:
        if c.id == conversation_id:
            return c
    raise HTTPException(status_code=404, detail="Conversation not found")

@router.get("/conversations/{conversation_id}/messages", response_model=List[MessageResponse])
async def get_messages(
    conversation_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve full message history for a conversation.
    """
    return await ChatService.get_messages(db, conversation_id, current_user.id)

@router.post("/conversations/{conversation_id}/messages", response_model=MessageResponse)
async def send_message(
    conversation_id: uuid.UUID,
    payload: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Send a message in a conversation via REST API (fallback for WebSocket).
    Persists message and broadcasts to WebSocket clients if recipient is connected.
    """
    msg_response = await ChatService.save_message(
        db, conversation_id, current_user.id, payload.content
    )

    # Broadcast via WebSocket manager
    ws_payload = {
        "type": "new_message",
        "message": {
            "id": str(msg_response.id),
            "conversation_id": str(msg_response.conversation_id),
            "sender_id": str(msg_response.sender_id),
            "sender_name": msg_response.sender_name,
            "content": msg_response.content,
            "is_read": msg_response.is_read,
            "created_at": msg_response.created_at.isoformat()
        }
    }
    await manager.broadcast_to_conversation(conversation_id, ws_payload)

    return msg_response

@router.patch("/conversations/{conversation_id}/read")
async def mark_read(
    conversation_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark unread messages in a conversation as read by the current user.
    """
    updated_count = await ChatService.mark_messages_as_read(db, conversation_id, current_user.id)

    # Broadcast read notice over WebSocket
    ws_payload = {
        "type": "messages_read",
        "conversation_id": str(conversation_id),
        "reader_id": str(current_user.id),
        "count": updated_count
    }
    await manager.broadcast_to_conversation(conversation_id, ws_payload)

    return {"status": "success", "updated_count": updated_count}

@router.get("/unread-count", response_model=UnreadCountResponse)
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get aggregate total count of unread messages for current user.
    """
    total = await ChatService.get_total_unread_count(db, current_user.id)
    return UnreadCountResponse(total_unread=total)

@router.get("/users/search", response_model=List[ChatUserSummary])
async def search_users(
    query: Optional[str] = Query(None, description="Search by user full name or email"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Search available users and alumni to initiate a new private chat.
    """
    return await ChatService.search_chat_users(db, current_user, query)

@router.websocket("/ws/{conversation_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    conversation_id: uuid.UUID,
    token: Optional[str] = Query(None)
):
    """
    WebSocket endpoint for real-time one-to-one messaging.
    Handshakes JWT token, authorizes user membership, persists sent messages,
    and broadcasts updates to connected conversation members.
    """
    if not token:
        await websocket.accept()
        await websocket.send_json({"type": "error", "message": "Authentication token required"})
        await websocket.close(code=4001)
        return

    # Decode token and authenticate user
    try:
        payload = decode_token(token)
        sub: str = payload.get("sub")
        if not sub:
            await websocket.accept()
            await websocket.send_json({"type": "error", "message": "Invalid token claims"})
            await websocket.close(code=4001)
            return
    except Exception:
        await websocket.accept()
        await websocket.send_json({"type": "error", "message": "Invalid authentication token"})
        await websocket.close(code=4001)
        return

    async with SessionLocal() as db:
        # Resolve user
        user_uuid = None
        try:
            user_uuid = uuid.UUID(sub)
        except ValueError:
            pass

        query = select(User).where((User.email == sub) | (User.phone_number == sub))
        if user_uuid:
            query = query.or_(User.id == user_uuid)

        user_res = await db.execute(query)
        user = user_res.scalars().first()

        if not user or not user.is_active:
            await websocket.accept()
            await websocket.send_json({"type": "error", "message": "User not authorized or inactive"})
            await websocket.close(code=4001)
            return

        # Authorize conversation membership
        try:
            await ChatService.get_conversation_by_id(db, conversation_id, user.id)
        except HTTPException as exc:
            await websocket.accept()
            await websocket.send_json({"type": "error", "message": exc.detail})
            await websocket.close(code=4003)
            return

        # Accept connection and register with connection manager
        await manager.connect(websocket, conversation_id, user.id)
        await websocket.send_json({
            "type": "connected",
            "conversation_id": str(conversation_id),
            "user_id": str(user.id)
        })

        try:
            while True:
                data = await websocket.receive_json()
                msg_type = data.get("type")

                if msg_type == "message":
                    content = data.get("content", "")
                    if not content or not content.strip():
                        await websocket.send_json({
                            "type": "error",
                            "message": "Message content cannot be empty"
                        })
                        continue

                    # Save message to database
                    msg_response = await ChatService.save_message(
                        db, conversation_id, user.id, content
                    )

                    # Broadcast payload to conversation channel
                    ws_payload = {
                        "type": "new_message",
                        "message": {
                            "id": str(msg_response.id),
                            "conversation_id": str(msg_response.conversation_id),
                            "sender_id": str(msg_response.sender_id),
                            "sender_name": msg_response.sender_name,
                            "content": msg_response.content,
                            "is_read": msg_response.is_read,
                            "created_at": msg_response.created_at.isoformat()
                        }
                    }
                    await manager.broadcast_to_conversation(conversation_id, ws_payload)

                elif msg_type == "read":
                    updated_count = await ChatService.mark_messages_as_read(db, conversation_id, user.id)
                    ws_payload = {
                        "type": "messages_read",
                        "conversation_id": str(conversation_id),
                        "reader_id": str(user.id),
                        "count": updated_count
                    }
                    await manager.broadcast_to_conversation(conversation_id, ws_payload)

                elif msg_type == "ping":
                    await websocket.send_json({"type": "pong"})

        except WebSocketDisconnect:
            manager.disconnect(websocket, conversation_id, user.id)
        except Exception as e:
            manager.disconnect(websocket, conversation_id, user.id)
