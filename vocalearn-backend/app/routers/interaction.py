from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Interaction, Module, User
from app.schemas import InteractionCreate, InteractionOut

router = APIRouter(prefix="/interactions", tags=["Interaksi Belajar"])


@router.post("", response_model=InteractionOut, status_code=201)
def create_interaction(
    req: InteractionCreate,
    db: Session = Depends(get_db),
    student: User = Depends(get_current_user),
):
    """Siswa mengirim hasil latihan ke AI engine."""
    if student.role != User.MAHASISWA:
        raise HTTPException(status_code=403, detail="Hanya mahasiswa yang bisa mencatat latihan")

    if db.get(Module, req.module_id) is None:
        raise HTTPException(status_code=404, detail="Modul tidak ditemukan")

    interaction = Interaction(
        student_id=student.id,
        module_id=req.module_id,
        score=req.score,
        correct_count=req.correct_count,
        total_questions=req.total_questions,
        duration_seconds=req.duration_seconds,
    )
    db.add(interaction)
    db.commit()
    db.refresh(interaction)
    return interaction


@router.get("/me", response_model=list[InteractionOut])
def my_interactions(
    db: Session = Depends(get_db),
    student: User = Depends(get_current_user),
):
    return (
        db.query(Interaction)
        .filter(Interaction.student_id == student.id)
        .order_by(Interaction.created_at.desc())
        .all()
    )
