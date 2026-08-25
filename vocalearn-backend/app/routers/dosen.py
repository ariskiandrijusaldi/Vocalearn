from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_dosen_or_admin
from app.models import Interaction, Kelas, Module, QuizResult, User
from app.schemas import ModuleOut

router = APIRouter(prefix="/dosen", tags=["Dosen"])


def _student_scores(db: Session, student_id: int) -> list[float]:
    scores = [
        float(i.score)
        for i in db.query(Interaction)
        .filter(Interaction.student_id == student_id)
        .all()
    ]
    scores += [
        float(q.skor)
        for q in db.query(QuizResult)
        .filter(QuizResult.student_id == student_id)
        .all()
    ]
    return scores


@router.get("/my-modules", response_model=list[ModuleOut])
def my_modules(
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    modules = (
        db.query(Module)
        .filter(Module.created_by == user.id)
        .order_by(Module.created_at.desc())
        .all()
    )
    result = []
    for m in modules:
        out = ModuleOut.model_validate(m)
        out_dict = out.model_dump()
        out_dict['creator_name'] = m.creator.full_name if m.creator else None
        out_dict['kelas_name'] = m.kelas.name if m.kelas else None
        result.append(ModuleOut(**out_dict))
    return result


@router.get("/students")
def list_students(
    kelas_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    q = db.query(User).filter(User.role == User.MAHASISWA)

    if user.role == User.DOSEN:
        dosen_kelas_ids = [
            k.id for k in db.query(Kelas).filter(Kelas.dosen_id == user.id).all()
        ]
        if dosen_kelas_ids:
            q = q.filter(User.kelas_id.in_(dosen_kelas_ids))
        else:
            q = q.filter(User.id == -1)
    elif kelas_id:
        q = q.filter(User.kelas_id == kelas_id)

    students = q.all()
    result = []
    for s in students:
        interactions = (
            db.query(Interaction)
            .filter(Interaction.student_id == s.id)
            .all()
        )
        scores = _student_scores(db, s.id)
        avg_score = sum(scores) / len(scores) if scores else 0.0
        kelas = db.get(Kelas, s.kelas_id) if s.kelas_id else None
        result.append({
            "id": s.id,
            "full_name": s.full_name,
            "email": s.email,
            "nim": s.nim,
            "prodi": s.prodi,
            "kelas_id": s.kelas_id,
            "kelas_name": kelas.name if kelas else None,
            "total_interactions": len(interactions),
            "avg_score": round(avg_score, 2),
        })
    return result


@router.get("/students/{student_id}")
def student_detail(
    student_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    student = db.get(User, student_id)
    if not student or student.role != User.MAHASISWA:
        raise HTTPException(status_code=404, detail="Mahasiswa tidak ditemukan")

    interactions = (
        db.query(Interaction)
        .filter(Interaction.student_id == student_id)
        .order_by(Interaction.created_at.desc())
        .all()
    )

    all_scores = _student_scores(db, student_id)
    overall_avg = sum(all_scores) / len(all_scores) if all_scores else 0.0

    modules_detail = []
    for i in interactions:
        module = db.get(Module, i.module_id)
        modules_detail.append({
            "interaction_id": i.id,
            "module_id": i.module_id,
            "module_title": module.title if module else "N/A",
            "score": i.score,
            "correct_count": i.correct_count,
            "total_questions": i.total_questions,
            "duration_seconds": i.duration_seconds,
            "created_at": i.created_at.isoformat() if i.created_at else None,
        })

    kelas = db.get(Kelas, student.kelas_id) if student.kelas_id else None
    return {
        "student": {
            "id": student.id,
            "full_name": student.full_name,
            "email": student.email,
            "nim": student.nim,
            "prodi": student.prodi,
            "kelas_id": student.kelas_id,
            "kelas_name": kelas.name if kelas else None,
        },
        "stats": {
            "total_interactions": len(interactions),
            "avg_score": round(overall_avg, 2),
        },
        "interactions": modules_detail,
    }
