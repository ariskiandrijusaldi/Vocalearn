from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMBase


class UserOut(ORMBase):
    id: int
    email: EmailStr
    full_name: str
    role: str
    nim: Optional[str] = None
    nip: Optional[str] = None
    prodi: Optional[str] = None
    kelas_id: Optional[int] = None
    kelas_name: Optional[str] = None
    is_active: bool
    created_at: datetime


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    full_name: str
    role: str
    nim: Optional[str] = None
    nip: Optional[str] = None
    prodi: Optional[str] = None
    kelas_id: Optional[int] = None


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    role: Optional[str] = None
    nim: Optional[str] = None
    nip: Optional[str] = None
    prodi: Optional[str] = None
    kelas_id: Optional[int] = None
    password: Optional[str] = Field(default=None, min_length=6)
    is_active: Optional[bool] = None


class ChangePassword(BaseModel):
    old_password: str
    new_password: str = Field(min_length=6)
