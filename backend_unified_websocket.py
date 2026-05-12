#!/usr/bin/env python3
"""
UNIFIED WEBSOCKET BACKEND - Conversation-Based Architecture
ALL events require conversation_id (heartbeat, send_message, typing, read_receipt)
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, Dict, Any
import jwt
import json
import uuid
from datetime import datetime
from pydantic import BaseModel, ValidationError, field_validator
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(title="Gruve WebSocket - Unified")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# UNIFIED EVENT SCHEMA - ALL events require conversation_id
# ============================================================================

class BaseEvent(BaseModel):
    """Base event with required conversation_id"""
    conversation_id: str
    timestamp: Optional[int] = None
    
    @field_validator('conversation_id')
    @classmethod
    def validate_conversation_id(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError('conversation_id is required and cannot be empty')
        try:
            uuid.UUID(v)
        except ValueError:
            raise ValueError('conversation_id must be a valid UUID string')
        return v

class HeartbeatEvent(BaseEvent):
    """Heartbeat event - REQUIRES conversation_id"""
    type: str = "heartbeat"
    action: str = "ping"

class MessageEvent(BaseEvent):
    """Message event - REQUIRES conversation_id"""
    type: str = "send_message"
    content: str
    sender_id: str
    
    @field_validator('content')
    @classmethod
    def validate_content(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError('content is required and cannot be empty')
        return v

class TypingEvent(BaseEvent):
    """Typing indicator - REQUIRES conversation_id"""
    type: str = "typing"
    is_typing: bool

class ReadReceiptEvent(BaseEvent):
    """Read receipt - REQUIRES conversation_id"""
    type: str = "read_receipt"
    message_id: str

# ============================================================================
# UNIFIED EVENT ROUTER
# ============================================================================

class UnifiedEventRouter:
    """Routes ALL events with conversation_id validation"""
    
    def __init__(self):
        self.handlers = {
            "heartbeat": self.handle_heartbeat,
            "send_message": self.handle_message,
            "typing": self.handle_typing,
            "read_receipt": self.handle_read_receipt,
        }
    
    async def route(self, websocket: WebSocket, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Route event with unified validation"""
        event_type = data.get("type")
        
        logger.info(f"[ROUTE] type={event_type} user={user_id} conv={data.get('conversation_id', 'MISSING')}")
        
        if event_type not in self.handlers:
            return self._error("unknown_event", f"Unknown type: {event_type}")
        
        # CRITICAL: Check conversation_id BEFORE routing
        if not data.get("conversation_id"):
            return self._error(
                "missing_conversation_id",
                "conversation_id is required and must be UUID string.",
                {"event_type": event_type}
            )
        
        try:
            return await self.handlers[event_type](websocket, user_id, data)
        except ValidationError as e:
            logger.error(f"[VALIDATION] {event_type}: {e}")
            return self._error("validation_error", str(e))
        except Exception as e:
            logger.error(f"[HANDLER] {event_type}: {e}")
            return self._error("handler_error", str(e))
    
    async def handle_heartbeat(self, websocket: WebSocket, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Heartbeat - REQUIRES conversation_id"""
        heartbeat = HeartbeatEvent(**data)
        
        response_time = None
        if heartbeat.timestamp:
            response_time = int(datetime.utcnow().timestamp() * 1000) - heartbeat.timestamp
        
        logger.info(f"[HEARTBEAT] user={user_id} conv={heartbeat.conversation_id} rt={response_time}ms")
        
        return {
            "type": "pong",
            "conversation_id": heartbeat.conversation_id,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
            "response_time": response_time
        }
    
    async def handle_message(self, websocket: WebSocket, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Message - REQUIRES conversation_id"""
        message = MessageEvent(**data)
        message_id = str(uuid.uuid4())
        
        logger.info(f"[MESSAGE] user={user_id} conv={message.conversation_id} msg={message_id}")
        
        return {
            "type": "message_received",
            "message_id": message_id,
            "conversation_id": message.conversation_id,
            "sender_id": message.sender_id,
            "content": message.content,
            "timestamp": int(datetime.utcnow().timestamp() * 1000),
            "status": "delivered"
        }
    
    async def handle_typing(self, websocket: WebSocket, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Typing indicator - REQUIRES conversation_id"""
        typing = TypingEvent(**data)
        
        logger.info(f"[TYPING] user={user_id} conv={typing.conversation_id} typing={typing.is_typing}")
        
        return {
            "type": "typing_ack",
            "conversation_id": typing.conversation_id,
            "is_typing": typing.is_typing,
            "timestamp": int(datetime.utcnow().timestamp() * 1000)
        }
    
    async def handle_read_receipt(self, websocket: WebSocket, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Read receipt - REQUIRES conversation_id"""
        receipt = ReadReceiptEvent(**data)
        
        logger.info(f"[READ] user={user_id} conv={receipt.conversation_id} msg={receipt.message_id}")
        
        return {
            "type": "read_ack",
            "conversation_id": receipt.conversation_id,
            "message_id": receipt.message_id,
            "timestamp": int(datetime.utcnow().timestamp() * 1000)
        }
    
    def _error(self, code: str, message: str, details: Dict[str, Any] = None) -> Dict[str, Any]:
        error_response = {
            "type": "error",
            "error": code,
            "detail": message,
            "timestamp": int(datetime.utcnow().timestamp() * 1000)
        }
        if details:
            error_response["details"] = details
        return error_response

# ============================================================================
# CONNECTION MANAGER
# ============================================================================

class ConnectionManager:
    def __init__(self):
        self.connections: Dict[str, WebSocket] = {}
        self.router = UnifiedEventRouter()
    
    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self.connections[user_id] = websocket
        
        logger.info(f"[CONNECT] user={user_id} total={len(self.connections)}")
        
        await websocket.send_json({
            "type": "connection_established",
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    def disconnect(self, user_id: str):
        if user_id in self.connections:
            del self.connections[user_id]
        logger.info(f"[DISCONNECT] user={user_id} total={len(self.connections)}")
    
    async def handle_message(self, user_id: str, message: str):
        if user_id not in self.connections:
            return
        
        websocket = self.connections[user_id]
        
        try:
            data = json.loads(message)
            response = await self.router.route(websocket, user_id, data)
            
            if response:
                await websocket.send_json(response)
        
        except json.JSONDecodeError:
            await websocket.send_json(self.router._error("invalid_json", "Invalid JSON"))
        except Exception as e:
            logger.error(f"[ERROR] user={user_id}: {e}")
            await websocket.send_json(self.router._error("internal_error", str(e)))

manager = ConnectionManager()

# ============================================================================
# JWT VALIDATION
# ============================================================================

SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"

def validate_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except:
        return None

# ============================================================================
# WEBSOCKET ENDPOINT
# ============================================================================

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: Optional[str] = Query(None)):
    logger.info("[WS] Connection attempt")
    
    await websocket.accept()
    
    if not token:
        logger.warning("[WS] No token")
        await websocket.close(code=1008, reason="Missing token")
        return
    
    user_id = validate_token(token)
    if not user_id:
        logger.warning("[WS] Invalid token")
        await websocket.close(code=1008, reason="Invalid token")
        return
    
    await manager.connect(user_id, websocket)
    
    try:
        while True:
            data = await websocket.receive_text()
            await manager.handle_message(user_id, data)
    
    except WebSocketDisconnect:
        manager.disconnect(user_id)
    except Exception as e:
        logger.error(f"[WS] Error: {e}")
        manager.disconnect(user_id)

# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "connections": len(manager.connections),
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    
    logger.info("=" * 70)
    logger.info("🚀 Gruve WebSocket - UNIFIED ARCHITECTURE")
    logger.info("=" * 70)
    logger.info("📍 Endpoint: ws://localhost:8001/ws")
    logger.info("🔐 ALL events require conversation_id (UUID)")
    logger.info("")
    logger.info("📝 Event Types:")
    logger.info("  • heartbeat: {'type': 'heartbeat', 'action': 'ping', 'conversation_id': 'UUID'}")
    logger.info("  • send_message: {'type': 'send_message', 'conversation_id': 'UUID', 'content': '...'}")
    logger.info("  • typing: {'type': 'typing', 'conversation_id': 'UUID', 'is_typing': true}")
    logger.info("  • read_receipt: {'type': 'read_receipt', 'conversation_id': 'UUID', 'message_id': 'UUID'}")
    logger.info("=" * 70)
    
    uvicorn.run(app, host="0.0.0.0", port=8001, log_level="info")
