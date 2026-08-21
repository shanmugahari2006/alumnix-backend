import uuid
import json
import logging
from typing import Dict, Set
from fastapi import WebSocket

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        # Maps conversation_id -> set of WebSocket connections
        self.active_conversations: Dict[uuid.UUID, Set[WebSocket]] = {}
        # Maps user_id -> set of WebSocket connections
        self.user_connections: Dict[uuid.UUID, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, conversation_id: uuid.UUID, user_id: uuid.UUID):
        await websocket.accept()

        if conversation_id not in self.active_conversations:
            self.active_conversations[conversation_id] = set()
        self.active_conversations[conversation_id].add(websocket)

        if user_id not in self.user_connections:
            self.user_connections[user_id] = set()
        self.user_connections[user_id].add(websocket)

        logger.info(f"User {user_id} connected to conversation {conversation_id}")

    def disconnect(self, websocket: WebSocket, conversation_id: uuid.UUID, user_id: uuid.UUID):
        if conversation_id in self.active_conversations:
            self.active_conversations[conversation_id].discard(websocket)
            if not self.active_conversations[conversation_id]:
                del self.active_conversations[conversation_id]

        if user_id in self.user_connections:
            self.user_connections[user_id].discard(websocket)
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]

        logger.info(f"User {user_id} disconnected from conversation {conversation_id}")

    async def broadcast_to_conversation(self, conversation_id: uuid.UUID, message_dict: dict):
        if conversation_id in self.active_conversations:
            connections = list(self.active_conversations[conversation_id])
            for connection in connections:
                try:
                    await connection.send_json(message_dict)
                except Exception as e:
                    logger.error(f"Error broadcasting to WebSocket in conversation {conversation_id}: {e}")

    async def send_to_user(self, user_id: uuid.UUID, message_dict: dict):
        if user_id in self.user_connections:
            connections = list(self.user_connections[user_id])
            for connection in connections:
                try:
                    await connection.send_json(message_dict)
                except Exception as e:
                    logger.error(f"Error sending to WebSocket for user {user_id}: {e}")

    def is_user_online(self, user_id: uuid.UUID) -> bool:
        return user_id in self.user_connections and len(self.user_connections[user_id]) > 0

manager = ConnectionManager()
