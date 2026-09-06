from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user, require_super_admin
from app.models import Jurusan, Prodi, User
from app.schemas import (
    JurusanCreate,
    JurusanOut,
    JurusanUpdate,
    ProdiCreate,
    ProdiOut,
    ProdiUpdate,
)

router = APIRouter(prefix="/jurusan", tags=["Jurusan & Prodi"])


def get_jurusan_or_404(db: Session, jurusan_id: int) -> Jurusan:
    j = db.get(Jurusan, jurusan_id)
    if j is None:
        raise HTTPException(status_code=404, detail="Jurusan tidak ditemukan")
    return j


def get_prodi_or_404(db: Session, prodi_id: int) -> Prodi:
    p = db.get(Prodi, prodi_id)
    if p is None:
        raise HTTPException(status_code=404, detail="Program studi tidak ditemukan")
    return p


# ==================== PRODI ====================
# (dideklarasikan sebelum `/{jurusan_id}` agar tidak menabrak path param)


@router.get("/prodi", response_model=list[ProdiOut])
def list_prodi(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return db.query(Prodi).order_by(Prodi.name).all()


@router.patch("/prodi/{prodi_id}", response_model=ProdiOut)
def update_prodi_route(
    prodi_id: int,
    req: ProdiUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    p = get_prodi_or_404(db, prodi_id)
    if req.name is not None:
        exists = (
            db.query(Prodi)
            .filter(Prodi.name == req.name, Prodi.id != prodi_id)
            .first()
        )
        if exists:
            raise HTTPException(status_code=400, detail="Nama program studi sudah ada")
        p.name = req.name
    db.commit()
    db.refresh(p)
    return p


@router.delete("/prodi/{prodi_id}", status_code=204)
def delete_prodi_route(
    prodi_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    p = get_prodi_or_404(db, prodi_id)
    db.delete(p)
    db.commit()


# ==================== JURUSAN ====================


@router.get("", response_model=list[JurusanOut])
def list_jurusan(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return db.query(Jurusan).order_by(Jurusan.name).all()


@router.post("", response_model=JurusanOut, status_code=201)
def create_jurusan_route(
    req: JurusanCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    if db.query(Jurusan).filter(Jurusan.name == req.name).first():
        raise HTTPException(status_code=400, detail="Nama jurusan sudah ada")
    j = Jurusan(name=req.name)
    db.add(j)
    db.commit()
    db.refresh(j)
    return j


@router.patch("/{jurusan_id}", response_model=JurusanOut)
def update_jurusan_route(
    jurusan_id: int,
    req: JurusanUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    j = get_jurusan_or_404(db, jurusan_id)
    if req.name is not None:
        exists = (
            db.query(Jurusan)
            .filter(Jurusan.name == req.name, Jurusan.id != jurusan_id)
            .first()
        )
        if exists:
            raise HTTPException(status_code=400, detail="Nama jurusan sudah ada")
        j.name = req.name
    db.commit()
    db.refresh(j)
    return j


@router.delete("/{jurusan_id}", status_code=204)
def delete_jurusan_route(
    jurusan_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    j = get_jurusan_or_404(db, jurusan_id)
    db.delete(j)
    db.commit()


@router.post("/{jurusan_id}/prodi", response_model=ProdiOut, status_code=201)
def create_prodi_route(
    jurusan_id: int,
    req: ProdiCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    j = get_jurusan_or_404(db, jurusan_id)
    if db.query(Prodi).filter(Prodi.name == req.name).first():
        raise HTTPException(status_code=400, detail="Nama program studi sudah ada")
    p = Prodi(name=req.name, jurusan_id=j.id)
    db.add(p)
    db.commit()
    db.refresh(p)
    return p