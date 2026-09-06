from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class ProdiOut(BaseModel):
    id: int
    name: str
    jurusan_id: int


class JurusanBase(BaseModel):
    name: str


class JurusanCreate(JurusanBase):
    pass


class JurusanUpdate(BaseModel):
    name: Optional[str] = None


class ProdiCreate(BaseModel):
    name: str


class ProdiUpdate(BaseModel):
    name: Optional[str] = None


class JurusanOut(JurusanBase, ORMBase):
    id: int
    created_at: datetime
    prodi: list[ProdiOut] = []