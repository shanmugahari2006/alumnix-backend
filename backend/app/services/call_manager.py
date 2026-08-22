import json
import logging
import uuid
from typing import Dict
from fastapi import WebSocket

logger = logging.getLogger("call_manager")

class CallManager:
    def __init__(self):
        # Map user_id (UUID) -> WebSocket connection
        self.active_connections: Dict[uuid.UUID, WebSocket] = {}

    async def connect(self, user_id: uuid.UUID, websocket: WebSocket):
        self.active_connections[user_id] = websocket
        logger.info(f"User {user_id} connected to signaling gateway.")

    def disconnect(self, user_id: uuid.UUID):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            logger.info(f"User {user_id} disconnected from signaling gateway.")

    async def send_to_user(self, user_id: uuid.UUID, message: dict) -> bool:
        websocket = self.active_connections.get(user_id)
        if websocket:
            try:
                await websocket.send_json(message)
                return True
            except Exception as e:
                logger.error(f"Error sending message to user {user_id}: {e}")
                self.disconnect(user_id)
        return False

call_manager = CallManager()
