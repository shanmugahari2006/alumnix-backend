import uuid
from typing import List
from fastapi import HTTPException
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.story import SuccessStory, StoryLike
from app.schemas.story import StoryCreate

class StoryService:
    @staticmethod
    async def create_story(db: AsyncSession, story_data: StoryCreate, author_id: uuid.UUID) -> SuccessStory:
        """
        Creates a new success story posting.
        """
        story = SuccessStory(
            title=story_data.title,
            content=story_data.content,
            author_id=author_id,
            likes_count=0
        )
        db.add(story)
        await db.commit()
        await db.refresh(story)
        return story

    @staticmethod
    async def list_stories(db: AsyncSession) -> List[SuccessStory]:
        """
        Retrieves all success stories ordered by created_at descending, eager loading the author object.
        """
        query = select(SuccessStory).options(selectinload(SuccessStory.author)).order_by(SuccessStory.created_at.desc())
        result = await db.execute(query)
        return result.scalars().all()

    @staticmethod
    async def toggle_like(db: AsyncSession, story_id: uuid.UUID, user_id: uuid.UUID) -> tuple[bool, int]:
        """
        Liking and unliking toggle check logic.
        """
        story_res = await db.execute(select(SuccessStory).where(SuccessStory.id == story_id))
        story = story_res.scalars().first()
        if not story:
            raise HTTPException(status_code=404, detail="Success story not found")

        like_res = await db.execute(
            select(StoryLike).where(StoryLike.story_id == story_id, StoryLike.user_id == user_id)
        )
        like = like_res.scalars().first()

        if like:
            await db.delete(like)
            story.likes_count = max(0, story.likes_count - 1)
            liked = False
        else:
            new_like = StoryLike(story_id=story_id, user_id=user_id)
            db.add(new_like)
            story.likes_count += 1
            liked = True

        await db.commit()
        await db.refresh(story)
        return liked, story.likes_count
