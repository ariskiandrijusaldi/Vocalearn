from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import User, UserRole
from app.schemas import UserUpdate
from app.security import hash_password


def get_user_or_404(db: Session, user_id: int) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    return user


def create_user(
    db: Session,
    *,
    email: str,
    password: str,
    full_name: str,
    role: str,
    nim: str | None = None,
    nip: str | None = None,
    prodi: str | None = None,
) -> User:
    if role not in UserRole.ALL:
        raise HTTPException(status_code=400, detail="Role tidak dikenal")
    if db.query(User).filter(User.email == email.lower()).first():
        raise HTTPException(status_code=400, detail="Email sudah terdaftar")

    user = User(
        email=email.lower(),
        password_hash=hash_password(password),
        full_name=full_name,
        role=role,
        nim=nim,
        nip=nip,
        prodi=prodi,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def update_user(db: Session, user_id: int, req: UserUpdate) -> User:
    user = get_user_or_404(db, user_id)
    data = req.model_dump(exclude_unset=True)
    if "password" in data and data["password"]:
        data["password_hash"] = hash_password(data.pop("password"))
    data.pop("password", None)
    for field, value in data.items():
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user


def soft_delete_user(db: Session, user_id: int) -> None:
    """Soft delete: nonaktifkan akun agar riwayat interaksi tetap utuh."""
    user = get_user_or_404(db, user_id)
    user.is_active = False
    db.commit()
