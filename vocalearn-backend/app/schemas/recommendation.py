from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.module import ModuleOut


class CompetencyOut(BaseModel):
    module_id: int
    module_title: str
    course_id: int
    mastery: float  # 0..1
    attempts: int


class RiskOut(BaseModel):
    level: str  # low | medium | high
    average_score: float
    attempt_count: int
    reasons: list[str]


class RecommendationOut(BaseModel):
    student_id: int
    generated_at: datetime
    risk: RiskOut
    competencies: list[CompetencyOut]
    next_module: Optional[ModuleOut] = None
    reason: str
    ai_suggestion: Optional[str] = None
