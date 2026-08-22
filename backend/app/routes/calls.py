import uuid
import json
import logging
from typing import Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database import get_db
from app.models.user import User
from app.utils.security import decode_token
from app.services.call_manager import call_manager

router = APIRouter()
logger = logging.getLogger("calls_router")

@router.websocket("/ws/calls/signal")
async def webrtc_signaling_endpoint(
    websocket: WebSocket,
    token: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    if not token:
        await websocket.accept()
        await websocket.send_json({"type": "error", "message": "Authentication token required"})
        await websocket.close(code=4001)
        return

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

    # Fetch user from db
    query = select(User).where((User.email == sub) | (User.phone_number == sub))
    try:
        # Check if sub is a UUID
        user_uuid = uuid.UUID(sub)
        query = select(User).where(User.id == user_uuid)
    except ValueError:
        pass

    res = await db.execute(query)
    user = res.scalars().first()

    if not user or not user.is_active:
        await websocket.accept()
        await websocket.send_json({"type": "error", "message": "User not authorized or inactive"})
        await websocket.close(code=4001)
        return

    await websocket.accept()
    await call_manager.connect(user.id, websocket)

    try:
        while True:
            data_str = await websocket.receive_text()
            try:
                data = json.loads(data_str)
            except json.JSONDecodeError:
                await websocket.send_json({"type": "error", "message": "Invalid JSON format"})
                continue

            event_type = data.get("event_type")
            target_id_str = data.get("target_id")
            payload = data.get("payload")

            if not event_type or not target_id_str:
                continue

            try:
                target_id = uuid.UUID(target_id_str)
            except ValueError:
                await websocket.send_json({"type": "error", "message": "Invalid target_id UUID format"})
                continue

            # Route call events
            if event_type == "call-initiate":
                call_id = str(uuid.uuid4())
                room_id = payload.get("room_id") if payload else f"room-{call_id}"
                
                # Relay to receiver as incoming-call
                await call_manager.send_to_user(target_id, {
                    "event_type": "incoming-call",
                    "caller_id": str(user.id),
                    "caller_name": user.full_name,
                    "room_id": room_id,
                    "call_id": call_id
                })
            else:
                # Standard relay for WebRTC SDP / ICE candidate / Decline / End
                # We forward the payload and attach sender_id to show who sent it.
                await call_manager.send_to_user(target_id, {
                    "event_type": event_type,
                    "sender_id": str(user.id),
                    "payload": payload
                })

    except WebSocketDisconnect:
        call_manager.disconnect(user.id)
    except Exception as e:
        logger.error(f"WebSocket error for user {user.id}: {e}")
        call_manager.disconnect(user.id)
