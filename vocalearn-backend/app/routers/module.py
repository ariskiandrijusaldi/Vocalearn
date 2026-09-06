import os
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user, require_dosen_or_admin, require_super_admin
from app.models import Module, User
from app.schemas import ModuleCreate, ModuleOut, ModuleReview, ModuleUpdate
from app.services.module_service import (
    approve_module,
    create_module,
    delete_module,
    get_module_or_404,
    publish_module,
    reject_module,
    submit_for_review,
    update_module,
)

router = APIRouter(prefix="/modules", tags=["Modul Praktik"])

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads", "modules")
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _module_out(m: Module) -> ModuleOut:
    out = ModuleOut.model_validate(m)
    out_dict = out.model_dump()
    out_dict['creator_name'] = m.creator.full_name if m.creator else None
    out_dict['kelas_name'] = m.kelas.name if m.kelas else None
    return ModuleOut(**out_dict)


@router.get("", response_model=list[ModuleOut])
def list_modules(
    status: str | None = None,
    course_id: int | None = None,
    kelas_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    q = db.query(Module)
    if status:
        q = q.filter(Module.status == status)
    if course_id:
        q = q.filter(Module.course_id == course_id)

    if user.role == User.MAHASISWA:
        if user.kelas_id:
            q = q.filter(
                (Module.kelas_id == user.kelas_id) | (Module.kelas_id.is_(None))
            )
        else:
            q = q.filter(Module.kelas_id.is_(None))
    elif kelas_id:
        q = q.filter(Module.kelas_id == kelas_id)

    modules = q.order_by(Module.course_id, Module.order_index).all()
    return [_module_out(m) for m in modules]


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
    return update_module(db, module_id, req, user=user)


@router.delete("/{module_id}", status_code=204)
def delete_module_route(
    module_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    delete_module(db, module_id, user=user)


@router.post("/{module_id}/upload-pdf", response_model=ModuleOut)
def upload_module_pdf(
    module_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Hanya file PDF yang diperbolehkan")

    mod = get_module_or_404(db, module_id)

    ext = os.path.splitext(file.filename)[1].lower()
    filename = f"module_{module_id}_{uuid.uuid4().hex[:8]}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(file.file.read())

    mod.pdf_path = filename
    db.commit()
    db.refresh(mod)
    return mod


@router.post("/{module_id}/submit", response_model=ModuleOut)
def submit_module_route(
    module_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    return submit_for_review(db, module_id)


@router.post("/{module_id}/approve", response_model=ModuleOut)
def approve_module_route(
    module_id: int,
    req: ModuleReview | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    return approve_module(db, module_id, reviewed_by=user.id, note=req.note if req else None)


@router.post("/{module_id}/publish", response_model=ModuleOut)
def publish_module_route(
    module_id: int,
    req: ModuleReview | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    return publish_module(db, module_id, reviewed_by=user.id, note=req.note if req else None)


@router.post("/{module_id}/reject", response_model=ModuleOut)
def reject_module_route(
    module_id: int,
    req: ModuleReview | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    return reject_module(db, module_id, reviewed_by=user.id, note=req.note if req else None)
