from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user, require_dosen_or_admin, require_super_admin
from app.models import Module, User
from app.schemas import ModuleCreate, ModuleOut, ModuleReview, ModuleUpdate
from app.services.module_service import (
    approve_module,
    create_module,
    get_module_or_404,
    reject_module,
    submit_for_review,
    update_module,
)

router = APIRouter(prefix="/modules", tags=["Modul Praktik"])

# Alur status: draft -> review -> published (reject mengembalikan ke draft)


@router.get("", response_model=list[ModuleOut])
def list_modules(
    status: str | None = None,
    course_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    q = db.query(Module)
    if status:
        q = q.filter(Module.status == status)
    if course_id:
        q = q.filter(Module.course_id == course_id)
    return q.order_by(Module.course_id, Module.order_index).all()


@router.get("/{module_id}", response_model=ModuleOut)
def get_module(
    module_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return get_module_or_404(db, module_id)


@router.post("", response_model=ModuleOut, status_code=201)
def create_module_route(
    req: ModuleCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    return create_module(db, req, created_by=user.id)


@router.patch("/{module_id}", response_model=ModuleOut)
def update_module_route(
    module_id: int,
    req: ModuleUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    return update_module(db, module_id, req)


@router.post("/{module_id}/submit", response_model=ModuleOut)
def submit_module_route(
    module_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    """draft -> review (diajukan dosen)."""
    return submit_for_review(db, module_id)


@router.post("/{module_id}/approve", response_model=ModuleOut)
def approve_module_route(
    module_id: int,
    req: ModuleReview | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    """review -> published (disetujui super admin)."""
    return approve_module(db, module_id, reviewed_by=user.id, note=req.note if req else None)


@router.post("/{module_id}/reject", response_model=ModuleOut)
def reject_module_route(
    module_id: int,
    req: ModuleReview | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    """review -> draft (ditolak, kembali ke dosen)."""
    return reject_module(db, module_id, reviewed_by=user.id, note=req.note if req else None)
