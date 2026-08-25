from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user, require_dosen_or_admin, require_super_admin
from app.models import Course, User
from app.schemas import CourseCreate, CourseOut, CourseUpdate
from app.services.course_service import (
    create_course,
    delete_course,
    get_course_or_404,
    update_course,
)

router = APIRouter(prefix="/courses", tags=["Mata Kuliah"])

# Referensi unit kompetensi SKKNI (bidang komunikasi & bahasa) untuk dropdown mapping
SKKNI_REFERENCE = [
    {"code": "K.01", "unit": "Komunikasi Efektif dalam Bahasa Asing"},
    {"code": "K.02", "unit": "Menyusun Korespondensi Bisnis"},
    {"code": "K.03", "unit": "Presentasi dalam Bahasa Asing"},
    {"code": "K.04", "unit": "Interaksi Lisan Dasar (listening & speaking)"},
    {"code": "K.05", "unit": "Keterampilan Membaca dan Menulis Akademik"},
    {"code": "K.06", "unit": "Persiapan Sertifikasi Profesi Bahasa"},
]


@router.get("/skkni")
def list_skkni_reference():
    """Daftar unit SKKNI untuk dropdown saat mapping mata kuliah."""
    return {"data": SKKNI_REFERENCE}


@router.get("", response_model=list[CourseOut])
def list_courses(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return db.query(Course).order_by(Course.code).all()


@router.get("/{course_id}", response_model=CourseOut)
def get_course(
    course_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return get_course_or_404(db, course_id)


@router.post("", response_model=CourseOut, status_code=201)
def create_course_route(
    req: CourseCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    return create_course(db, req)


@router.patch("/{course_id}", response_model=CourseOut)
def update_course_route(
    course_id: int,
    req: CourseUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_dosen_or_admin),
):
    return update_course(db, course_id, req)


@router.delete("/{course_id}", status_code=204)
def delete_course_route(
    course_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_super_admin),
):
    delete_course(db, course_id)
