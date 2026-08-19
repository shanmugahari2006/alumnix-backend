import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock

@pytest.mark.asyncio
async def test_upload_resume_success(client: AsyncClient):
    # Mock supabase client calls
    with patch("app.utils.storage.supabase_client") as mock_supabase:
        mock_bucket = MagicMock()
        mock_bucket.upload.return_value = {"path": "test.pdf"}
        mock_bucket.get_public_url.return_value = "https://supabase.co/storage/v1/object/public/resumes/unique_test.pdf"
        mock_supabase.storage.from_.return_value = mock_bucket

        files = {"file": ("test.pdf", b"Fake PDF file contents", "application/pdf")}
        response = await client.post("/api/v1/upload/resume", files=files)
        
        assert response.status_code == 200
        data = response.json()
        assert data["filename"] == "test.pdf"
        assert data["url"] == "https://supabase.co/storage/v1/object/public/resumes/unique_test.pdf"
        
        # Verify the bucket was resolved as 'resumes'
        mock_supabase.storage.from_.assert_called_with("resumes")

@pytest.mark.asyncio
async def test_upload_resume_invalid_type(client: AsyncClient):
    files = {"file": ("test.png", b"Fake PNG file contents", "image/png")}
    response = await client.post("/api/v1/upload/resume", files=files)
    
    assert response.status_code == 400
    assert "Only PDF files are allowed" in response.json()["detail"]

@pytest.mark.asyncio
async def test_upload_resume_size_exceeded(client: AsyncClient):
    # Create content larger than 5MB
    large_content = b"a" * (5 * 1024 * 1024 + 1)
    files = {"file": ("test.pdf", large_content, "application/pdf")}
    response = await client.post("/api/v1/upload/resume", files=files)
    
    assert response.status_code == 400
    assert "File size exceeds the maximum limit of 5MB" in response.json()["detail"]

@pytest.mark.asyncio
async def test_upload_avatar_success_png(client: AsyncClient):
    with patch("app.utils.storage.supabase_client") as mock_supabase:
        mock_bucket = MagicMock()
        mock_bucket.upload.return_value = {"path": "avatar.png"}
        mock_bucket.get_public_url.return_value = "https://supabase.co/storage/v1/object/public/avatars/unique_avatar.png"
        mock_supabase.storage.from_.return_value = mock_bucket

        files = {"file": ("avatar.png", b"Fake PNG image contents", "image/png")}
        response = await client.post("/api/v1/upload/avatar", files=files)
        
        assert response.status_code == 200
        data = response.json()
        assert data["filename"] == "avatar.png"
        assert data["url"] == "https://supabase.co/storage/v1/object/public/avatars/unique_avatar.png"
        
        mock_supabase.storage.from_.assert_called_with("avatars")

@pytest.mark.asyncio
async def test_upload_avatar_success_jpeg(client: AsyncClient):
    with patch("app.utils.storage.supabase_client") as mock_supabase:
        mock_bucket = MagicMock()
        mock_bucket.upload.return_value = {"path": "avatar.jpg"}
        mock_bucket.get_public_url.return_value = "https://supabase.co/storage/v1/object/public/avatars/unique_avatar.jpg"
        mock_supabase.storage.from_.return_value = mock_bucket

        files = {"file": ("avatar.jpg", b"Fake JPEG image contents", "image/jpeg")}
        response = await client.post("/api/v1/upload/avatar", files=files)
        
        assert response.status_code == 200
        data = response.json()
        assert data["filename"] == "avatar.jpg"
        assert data["url"] == "https://supabase.co/storage/v1/object/public/avatars/unique_avatar.jpg"

@pytest.mark.asyncio
async def test_upload_avatar_invalid_type(client: AsyncClient):
    files = {"file": ("doc.pdf", b"Fake PDF contents", "application/pdf")}
    response = await client.post("/api/v1/upload/avatar", files=files)
    
    assert response.status_code == 400
    assert "Only JPEG and PNG images are allowed" in response.json()["detail"]

@pytest.mark.asyncio
async def test_upload_avatar_size_exceeded(client: AsyncClient):
    # Create content larger than 2MB
    large_content = b"a" * (2 * 1024 * 1024 + 1)
    files = {"file": ("avatar.png", large_content, "image/png")}
    response = await client.post("/api/v1/upload/avatar", files=files)
    
    assert response.status_code == 400
    assert "File size exceeds the maximum limit of 2MB" in response.json()["detail"]
