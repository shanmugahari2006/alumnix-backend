import uuid
from datetime import datetime
from pydantic import BaseModel, Field

class StoryCreate(BaseModel):
    title: str = Field(..., min_length=1)
    content: str = Field(..., min_length=1)

class StoryResponse(BaseModel):
    id: uuid.UUID
    title: str
    content: str
    author_id: uuid.UUID
    likes_count: int
    created_at: datetime
    author_name: str
    model_config = {"from_attributes": True}

class LikeToggleResponse(BaseModel):
    story_id: uuid.UUID
    liked: bool
    likes_count: int
