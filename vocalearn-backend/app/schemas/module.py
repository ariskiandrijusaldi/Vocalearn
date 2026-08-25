from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class ModuleCreate(BaseModel):
    course_id: int
    title: str
    description: Optional[str] = None
    content: Optional[str] = None
    difficulty: int = 1
    order_index: int = 0
    youtube_url: Optional[str] = None
    kelas_id: Optional[int] = None


class ModuleUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    difficulty: Optional[int] = None
    order_index: Optional[int] = None
    youtube_url: Optional[str] = None
    kelas_id: Optional[int] = None


class ModuleReview(BaseModel):
    note: Optional[str] = None


class ModuleOut(ORMBase):
    id: int
    course_id: int
    title: str
    description: Optional[str] = None
    content: Optional[str] = None
    difficulty: int
    order_index: int
    status: str
    created_by: Optional[int] = None
    creator_name: Optional[str] = None
    reviewed_by: Optional[int] = None
    review_note: Optional[str] = None
    pdf_path: Optional[str] = None
    youtube_url: Optional[str] = None
    kelas_id: Optional[int] = None
    kelas_name: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    published_at: Optional[datetime] = None
