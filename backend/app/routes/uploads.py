from fastapi import APIRouter, UploadFile, File, HTTPException, status, Depends
from app.utils.storage import StorageUtility
from app.dependencies import get_current_user
from app.models.user import User

router = APIRouter()

@router.post("/resume")
async def upload_resume(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Upload resume PDF to Supabase Storage resumes bucket.
    Max size: 5MB
    """
    # Enforce PDF only
    # Checking content_type first
    if file.content_type != "application/pdf":
        # Fallback check file extension if browser didn't supply content type
        ext = file.filename.split(".")[-1].lower() if "." in file.filename else ""
        if ext != "pdf":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid file type. Only PDF files are allowed for resumes."
            )
        
    contents = await file.read()
    file_size = len(contents)
    
    # Enforce maximum size: 5MB
    if file_size > 5 * 1024 * 1024:
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size exceeds the maximum limit of 5MB."
        )
         
    try:
        public_url = await StorageUtility.upload_file(
            bucket_name="resumes",
            file_data=contents,
            file_name=file.filename,
            content_type="application/pdf"
        )
        return {"filename": file.filename, "url": public_url}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload file to storage: {str(e)}"
        )

@router.post("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Upload avatar JPEG/PNG to Supabase Storage avatars bucket.
    Max size: 2MB
    """
    # Enforce JPEG/PNG only
    allowed_types = ["image/jpeg", "image/png", "image/jpg"]
    if file.content_type not in allowed_types:
        ext = file.filename.split(".")[-1].lower() if "." in file.filename else ""
        if ext not in ["jpg", "jpeg", "png"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid file type. Only JPEG and PNG images are allowed."
            )
            
    contents = await file.read()
    file_size = len(contents)
    
    # Enforce maximum size: 2MB
    if file_size > 2 * 1024 * 1024:
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size exceeds the maximum limit of 2MB."
        )
         
    # Normalise content type for storage
    content_type = file.content_type
    if content_type not in allowed_types:
        ext = file.filename.split(".")[-1].lower()
        content_type = f"image/{'jpeg' if ext in ['jpg', 'jpeg'] else 'png'}"
         
    try:
        public_url = await StorageUtility.upload_file(
            bucket_name="avatars",
            file_data=contents,
            file_name=file.filename,
            content_type=content_type
        )
        return {"filename": file.filename, "url": public_url}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload file to storage: {str(e)}"
        )
