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


class ModuleUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    difficulty: Optional[int] = None
    order_index: Optional[int] = None


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
    created_by: int
    reviewed_by: Optional[int] = None
    review_note: Optional[str] = None
    created_at: datetime
    published_at: Optional[datetime] = None
