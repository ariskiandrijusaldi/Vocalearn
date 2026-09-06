from collections import Counter, defaultdict

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_super_admin
from app.models import Course, Enrollment, Interaction, Jurusan, Module, QuizResult, User
from app.schemas import (
    AdminStats,
    DailyActivity,
    JurusanStat,
    ModuleStatusCount,
    RoleCount,
    UserCreate,
    UserOut,
    UserUpdate,
)
from app.services.user_service import create_user, soft_delete_user, update_user

router = APIRouter(prefix="/admin", tags=["Super Admin"], dependencies=[Depends(require_super_admin)])


# ---------- Manajemen Pengguna ----------
def _user_out(u: User) -> UserOut:
    """Serialize user lengkap termasuk jurusan (untuk response create/update)."""
    return UserOut(
        id=u.id,
        email=u.email,
        full_name=u.full_name,
        role=u.role,
        nim=u.nim,
        nip=u.nip,
        prodi=u.prodi,
        kelas_id=u.kelas_id,
        kelas_name=u.kelas.name if u.kelas else None,
        jurusan_id=u.jurusan_id,
        jurusan_name=u.jurusan.name if u.jurusan else None,
        is_active=u.is_active,
        created_at=u.created_at,
    )


@router.get("/users", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db)):
    users = db.query(User).order_by(User.created_at.desc()).all()
    result = []
    for u in users:
        last_interaction = (
            db.query(func.max(Interaction.created_at))
            .filter(Interaction.student_id == u.id)
            .scalar()
        )
        last_quiz = (
            db.query(func.max(QuizResult.created_at))
            .filter(QuizResult.student_id == u.id)
            .scalar()
        )
        timestamps = [t for t in [last_interaction, last_quiz] if t is not None]
        last_active_at = max(timestamps) if timestamps else None
        kelas_name = u.kelas.name if u.kelas else None
        jurusan_name = u.jurusan.name if u.jurusan else None
        result.append(UserOut(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            role=u.role,
            nim=u.nim,
            nip=u.nip,
            prodi=u.prodi,
            kelas_id=u.kelas_id,
            kelas_name=kelas_name,
            jurusan_id=u.jurusan_id,
            jurusan_name=jurusan_name,
            is_active=u.is_active,
            created_at=u.created_at,
            last_active_at=last_active_at,
        ))
    result.sort(key=lambda x: x.last_active_at or x.created_at, reverse=True)
    return result


@router.post("/users", response_model=UserOut, status_code=201)
def create_user_route(req: UserCreate, db: Session = Depends(get_db)):
    user = create_user(
        db,
        email=req.email,
        password=req.password,
        full_name=req.full_name,
        role=req.role,
        nim=req.nim,
        nip=req.nip,
        prodi=req.prodi,
        kelas_id=req.kelas_id,
        jurusan_id=req.jurusan_id,
    )
    return _user_out(user)


@router.patch("/users/{user_id}", response_model=UserOut)
def update_user_route(user_id: int, req: UserUpdate, db: Session = Depends(get_db)):
    return _user_out(update_user(db, user_id, req))


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

    # ----- Statistik per jurusan (dari prodi yang terdaftar) -----
    courses = db.query(Course).all()
    course_by_id = {c.id: c for c in courses}
    modules = db.query(Module).all()
    module_by_id = {m.id: m for m in modules}

    prodi_course_count = Counter(c.prodi for c in courses if c.prodi)
    prodi_module_count = Counter(
        course_by_id[m.course_id].prodi
        for m in modules
        if m.course_id in course_by_id and course_by_id[m.course_id].prodi
    )
    prodi_student_count = Counter(
        u.prodi for u in db.query(User).filter(User.role == "mahasiswa").all() if u.prodi
    )
    prodi_interaction_scores: dict[str, list[float]] = defaultdict(list)
    for it in db.query(Interaction).all():
        m = module_by_id.get(it.module_id)
        if m is None or m.course_id not in course_by_id:
            continue
        prodi = course_by_id[m.course_id].prodi
        if prodi:
            prodi_interaction_scores[prodi].append(it.score)

    jurusan_stats = []
    for j in db.query(Jurusan).order_by(Jurusan.name).all():
        prodi_names = [p.name for p in j.prodi]
        scores = [
            s
            for p in prodi_names
            for s in prodi_interaction_scores.get(p, [])
        ]
        jurusan_stats.append(JurusanStat(
            id=j.id,
            name=j.name,
            total_prodi=len(prodi_names),
            total_students=sum(prodi_student_count.get(p, 0) for p in prodi_names),
            total_courses=sum(prodi_course_count.get(p, 0) for p in prodi_names),
            total_modules=sum(prodi_module_count.get(p, 0) for p in prodi_names),
            total_interactions=len(scores),
            avg_score=round(sum(scores) / len(scores), 2) if scores else 0.0,
        ))

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
        jurusan_stats=jurusan_stats,
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
