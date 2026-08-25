from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class KelasCreate(BaseModel):
    name: str
    dosen_id: Optional[int] = None
    description: Optional[str] = None


class KelasUpdate(BaseModel):
    name: Optional[str] = None
    dosen_id: Optional[int] = None
    description: Optional[str] = None


class KelasOut(ORMBase):
    id: int
    name: str
    dosen_id: Optional[int] = None
    dosen_name: Optional[str] = None
    description: Optional[str] = None
    created_at: datetime
