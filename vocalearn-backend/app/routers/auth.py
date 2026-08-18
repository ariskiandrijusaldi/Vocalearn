from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import User
from app.schemas import LoginRequest, RegisterRequest, TokenResponse, UserOut
from app.security import create_access_token, verify_password
from app.services.user_service import create_user

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email.lower()).first()
    if user is None or not verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Email atau password salah")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Akun Anda dinonaktifkan")

    token = create_access_token(subject=str(user.id), role=user.role)
    return TokenResponse(access_token=token)


@router.post("/register", response_model=UserOut)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    return create_user(
        db,
        email=req.email,
        password=req.password,
        full_name=req.full_name,
        role=req.role,
        nim=req.nim,
        nip=req.nip,
        prodi=req.prodi,
    )


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user
