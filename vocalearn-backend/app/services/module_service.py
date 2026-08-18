from datetime import datetime

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Course, Module, ModuleStatus
from app.schemas import ModuleCreate, ModuleUpdate


def get_module_or_404(db: Session, module_id: int) -> Module:
    mod = db.get(Module, module_id)
    if mod is None:
        raise HTTPException(status_code=404, detail="Modul tidak ditemukan")
    return mod


def create_module(db: Session, req: ModuleCreate, created_by: int) -> Module:
    if db.get(Course, req.course_id) is None:
        raise HTTPException(status_code=404, detail="Mata kuliah tidak ditemukan")

    mod = Module(
        course_id=req.course_id,
        title=req.title,
        description=req.description,
        content=req.content,
        difficulty=req.difficulty,
        order_index=req.order_index,
        status=ModuleStatus.DRAFT,
        created_by=created_by,
    )
    db.add(mod)
    db.commit()
    db.refresh(mod)
    return mod


def update_module(db: Session, module_id: int, req: ModuleUpdate) -> Module:
    mod = get_module_or_404(db, module_id)
    if mod.status == ModuleStatus.PUBLISHED:
        raise HTTPException(status_code=400, detail="Modul terbit tidak bisa diedit")

    for field, value in req.model_dump(exclude_unset=True).items():
        setattr(mod, field, value)
    db.commit()
    db.refresh(mod)
    return mod


def submit_for_review(db: Session, module_id: int) -> Module:
    """draft -> review (diajukan dosen)."""
    mod = get_module_or_404(db, module_id)
    if mod.status != ModuleStatus.DRAFT:
        raise HTTPException(status_code=400, detail="Hanya modul draft yang bisa diajukan")
    mod.status = ModuleStatus.REVIEW
    db.commit()
    db.refresh(mod)
    return mod


def approve_module(
    db: Session,
    module_id: int,
    reviewed_by: int,
    note: str | None = None,
) -> Module:
    """review -> published (disetujui super admin)."""
    mod = get_module_or_404(db, module_id)
    if mod.status != ModuleStatus.REVIEW:
        raise HTTPException(status_code=400, detail="Modul harus dalam status review")

    mod.status = ModuleStatus.PUBLISHED
    mod.reviewed_by = reviewed_by
    mod.review_note = note or "Disetujui"
    mod.published_at = datetime.now()
    db.commit()
    db.refresh(mod)
    return mod


def reject_module(
    db: Session,
    module_id: int,
    reviewed_by: int,
    note: str | None = None,
) -> Module:
    """review -> draft (ditolak, kembali ke dosen)."""
    mod = get_module_or_404(db, module_id)
    mod.status = ModuleStatus.DRAFT
    mod.reviewed_by = reviewed_by
    mod.review_note = note or "Ditolak, mohon direvisi"
    db.commit()
    db.refresh(mod)
    return mod
