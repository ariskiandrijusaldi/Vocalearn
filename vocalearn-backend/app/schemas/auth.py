from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    full_name: str
    role: str = "mahasiswa"
    nim: str
    nip: Optional[str] = None
    prodi: str
    kelas_id: int


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
