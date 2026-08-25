from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_super_admin
from app.models import Course, Enrollment, Interaction, Module, User
from app.schemas import (
    AdminStats,
    DailyActivity,
    ModuleStatusCount,
    RoleCount,
    UserCreate,
    UserOut,
    UserUpdate,
)
from app.services.user_service import create_user, soft_delete_user, update_user

router = APIRouter(prefix="/admin", tags=["Super Admin"], dependencies=[Depends(require_super_admin)])


# ---------- Manajemen Pengguna ----------
@router.get("/users", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db)):
    return db.query(User).order_by(User.created_at.desc()).all()


@router.post("/users", response_model=UserOut, status_code=201)
def create_user_route(req: UserCreate, db: Session = Depends(get_db)):
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


@router.patch("/users/{user_id}", response_model=UserOut)
def update_user_route(user_id: int, req: UserUpdate, db: Session = Depends(get_db)):
    return update_user(db, user_id, req)


@router.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    """Soft delete: nonaktifkan akun agar riwayat interaksi tetap utuh."""
    soft_delete_user(db, user_id)


# ---------- Monitoring Sistem ----------
@router.get("/stats", response_model=AdminStats)
def system_stats(db: Session = Depends(get_db)):
    users_by_role = db.query(User.role, func.count(User.id)).group_by(User.role).all()
    modules_by_status = (
        db.query(Module.status, func.count(Module.id)).group_by(Module.status).all()
    )

    daily = (
        db.query(
            func.date(Interaction.created_at).label("day"),
            func.count(Interaction.id).label("cnt"),
            func.avg(Interaction.score).label("avg"),
        )
        .group_by("day")
        .order_by("day")
        .limit(14)
        .all()
    )

    avg_score = db.query(func.avg(Interaction.score)).scalar() or 0.0

    return AdminStats(
        total_users=db.query(User).count(),
        users_by_role=[RoleCount(role=r, count=c) for r, c in users_by_role],
        total_courses=db.query(Course).count(),
        total_modules=db.query(Module).count(),
        modules_by_status=[ModuleStatusCount(status=s, count=c) for s, c in modules_by_status],
        total_interactions=db.query(Interaction).count(),
        avg_score=round(avg_score, 2),
        daily_activity=[
            DailyActivity(date=str(d), interactions=cnt, avg_score=round(avg or 0, 2))
            for d, cnt, avg in daily
        ],
    )


# ---------- Pengaturan Integrasi (mock target) ----------
@router.get("/integrations")
def integration_status(db: Session = Depends(get_db)):
    """Status koneksi ke sistem eksternal (SIAKAD / LSP). Dummy untuk sekarang."""
    return {
        "data": [
            {"key": "siakad", "name": "SIAKAD", "connected": False, "endpoint": "https://siakad.univ.ac.id/api"},
            {"key": "lsp", "name": "LSP", "connected": False, "endpoint": "https://lsp.example.id/api"},
        ]
    }
