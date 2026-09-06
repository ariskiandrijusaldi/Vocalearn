from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class CourseBase(BaseModel):
    code: str
    name: str
    prodi: Optional[str] = None
    semester: int = 1
    credits: int = 3
    skkni_unit: Optional[str] = None
    skkni_code: Optional[str] = None
    kkni_level: int = 6
    description: Optional[str] = None


class CourseCreate(CourseBase):
    pass


class CourseUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    prodi: Optional[str] = None
    semester: Optional[int] = None
    credits: Optional[int] = None
    skkni_unit: Optional[str] = None
    skkni_code: Optional[str] = None
    kkni_level: Optional[int] = None
    description: Optional[str] = None


class CourseOut(CourseBase, ORMBase):
    id: int
    created_at: datetime
