from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import User
from app.schemas import ChangePassword, LoginRequest, RegisterRequest, TokenResponse, UserOut
from app.security import create_access_token, hash_password, verify_password
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
        kelas_id=req.kelas_id,
    )


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    kelas_name = user.kelas.name if user.kelas else None
    jurusan_name = user.jurusan.name if user.jurusan else None
    data = {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role,
        "nim": user.nim,
        "nip": user.nip,
        "prodi": user.prodi,
        "kelas_id": user.kelas_id,
        "kelas_name": kelas_name,
        "jurusan_id": user.jurusan_id,
        "jurusan_name": jurusan_name,
        "is_active": user.is_active,
        "created_at": user.created_at,
    }
    return data


@router.post("/change-password")
def change_password(
    req: ChangePassword,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(req.old_password, user.password_hash):
        raise HTTPException(status_code=400, detail="Password lama salah")

    user.password_hash = hash_password(req.new_password)
    db.commit()
    return {"detail": "Password berhasil diubah"}
