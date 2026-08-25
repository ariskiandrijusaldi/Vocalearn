from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


class InteractionCreate(BaseModel):
    module_id: int
    score: float = Field(ge=0, le=100)
    correct_count: int = 0
    total_questions: int = 0
    duration_seconds: int = 0


class InteractionOut(ORMBase):
    id: int
    student_id: int
    module_id: int
    score: float
    correct_count: int
    total_questions: int
    duration_seconds: int
    created_at: datetime
