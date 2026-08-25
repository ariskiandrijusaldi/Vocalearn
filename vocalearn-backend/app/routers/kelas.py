from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_dosen_or_admin, require_super_admin
from app.models import Kelas, User
from app.schemas import KelasCreate, KelasOut, KelasUpdate

router = APIRouter(prefix="/kelas", tags=["Kelas"])


def _kelas_out(k: Kelas) -> KelasOut:
    return KelasOut(
        id=k.id,
        name=k.name,
        dosen_id=k.dosen_id,
        dosen_name=k.dosen.full_name if k.dosen else None,
        description=k.description,
        created_at=k.created_at,
    )


@router.get("/public", response_model=list[KelasOut])
def list_kelas_public(db: Session = Depends(get_db)):
    """Daftar kelas tanpa autentikasi — dipakai saat registrasi mahasiswa."""
    kelas_list = db.query(Kelas).order_by(Kelas.name).all()
    return [_kelas_out(k) for k in kelas_list]


@router.get("", response_model=list[KelasOut])
def list_kelas(
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    kelas_list = db.query(Kelas).order_by(Kelas.name).all()
    return [_kelas_out(k) for k in kelas_list]


@router.get("/{kelas_id}", response_model=KelasOut)
def get_kelas(
    kelas_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    k = db.get(Kelas, kelas_id)
    if not k:
        raise HTTPException(status_code=404, detail="Kelas tidak ditemukan")
    return _kelas_out(k)


@router.post("", response_model=KelasOut, status_code=201)
def create_kelas(
    req: KelasCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    if db.query(Kelas).filter(Kelas.name == req.name).first():
        raise HTTPException(status_code=400, detail="Nama kelas sudah ada")
    if req.dosen_id:
        dosen = db.get(User, req.dosen_id)
        if not dosen or dosen.role != User.DOSEN:
            raise HTTPException(status_code=400, detail="Dosen tidak valid")
    k = Kelas(name=req.name, dosen_id=req.dosen_id, description=req.description)
    db.add(k)
    db.commit()
    db.refresh(k)
    return _kelas_out(k)


@router.patch("/{kelas_id}", response_model=KelasOut)
def update_kelas(
    kelas_id: int,
    req: KelasUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    k = db.get(Kelas, kelas_id)
    if not k:
        raise HTTPException(status_code=404, detail="Kelas tidak ditemukan")
    if req.name and req.name != k.name:
        if db.query(Kelas).filter(Kelas.name == req.name).first():
            raise HTTPException(status_code=400, detail="Nama kelas sudah ada")
    if req.dosen_id:
        dosen = db.get(User, req.dosen_id)
        if not dosen or dosen.role != User.DOSEN:
            raise HTTPException(status_code=400, detail="Dosen tidak valid")
    for field, value in req.model_dump(exclude_unset=True).items():
        setattr(k, field, value)
    db.commit()
    db.refresh(k)
    return _kelas_out(k)


@router.delete("/{kelas_id}", status_code=204)
def delete_kelas(
    kelas_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    k = db.get(Kelas, kelas_id)
    if not k:
        raise HTTPException(status_code=404, detail="Kelas tidak ditemukan")
    db.delete(k)
    db.commit()
