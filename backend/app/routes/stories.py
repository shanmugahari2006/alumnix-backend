import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.user import User
from app.schemas.story import StoryCreate, StoryResponse, LikeToggleResponse
from app.services.story_service import StoryService
from app.dependencies import get_current_user, require_role

router = APIRouter()

@router.post("", response_model=StoryResponse, status_code=status.HTTP_201_CREATED)
async def create_story(
    payload: StoryCreate,
    current_user: User = Depends(require_role(["alumni", "admin"])),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new success story / promotion (Alumni and Admin only).
    """
    story = await StoryService.create_story(db, payload, current_user.id)
    return StoryResponse(
        id=story.id,
        title=story.title,
        content=story.content,
        author_id=story.author_id,
        likes_count=story.likes_count,
        created_at=story.created_at,
        author_name=current_user.full_name
    )

@router.get("", response_model=List[StoryResponse])
async def list_stories(db: AsyncSession = Depends(get_db)):
    """
    Get the feed of success stories ordered by created_at descending.
    """
    stories = await StoryService.list_stories(db)
    return [
        StoryResponse(
            id=s.id,
            title=s.title,
            content=s.content,
            author_id=s.author_id,
            likes_count=s.likes_count,
            created_at=s.created_at,
            author_name=s.author.full_name
        )
        for s in stories
    ]

@router.post("/{story_id}/like", response_model=LikeToggleResponse)
async def toggle_like_story(
    story_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Toggle liking a success story.
    """
    liked, likes_count = await StoryService.toggle_like(db, story_id, current_user.id)
    return LikeToggleResponse(story_id=story_id, liked=liked, likes_count=likes_count)
