import uuid
import asyncio
from supabase import create_client, Client
from app.config import settings

# Setup Supabase client using settings
supabase_client: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

class StorageUtility:
    @staticmethod
    async def upload_file(bucket_name: str, file_data: bytes, file_name: str, content_type: str) -> str:
        """
        Uploads file bytes to a Supabase Storage bucket and returns its public URL.
        """
        # Unique file path to prevent collision
        unique_name = f"{uuid.uuid4().hex}_{file_name}"
        
        # Run blocking upload in a separate thread
        await asyncio.to_thread(
            supabase_client.storage.from_(bucket_name).upload,
            path=unique_name,
            file=file_data,
            file_options={"content-type": content_type}
        )
        
        # Construct and return public URL
        public_url = supabase_client.storage.from_(bucket_name).get_public_url(unique_name)
        return public_url
