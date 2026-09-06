from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models import Course
from app.schemas import CourseCreate, CourseUpdate


def get_course_or_404(db: Session, course_id: int) -> Course:
    course = db.get(Course, course_id)
    if course is None:
        raise HTTPException(status_code=404, detail="Mata kuliah tidak ditemukan")
    return course


def create_course(db: Session, req: CourseCreate) -> Course:
    if db.query(Course).filter(Course.code == req.code).first():
        raise HTTPException(status_code=400, detail="Kode mata kuliah sudah ada")
    course = Course(**req.model_dump())
    db.add(course)
    db.commit()
    db.refresh(course)
    return course


def update_course(db: Session, course_id: int, req: CourseUpdate) -> Course:
    course = get_course_or_404(db, course_id)
    for field, value in req.model_dump(exclude_unset=True).items():
        setattr(course, field, value)
    db.commit()
    db.refresh(course)
    return course


def delete_course(db: Session, course_id: int) -> None:
    course = get_course_or_404(db, course_id)
    try:
        db.delete(course)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Mata kuliah tidak bisa dihapus karena masih digunakan oleh data lain",
        )
