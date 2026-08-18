from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_any_authenticated
from app.models import User
from app.schemas import RecommendationOut
from app.services.recommendation_service import get_student_recommendation

router = APIRouter(prefix="/recommendation", tags=["AI Adaptive Engine"])


@router.get("/{student_id}", response_model=RecommendationOut)
def get_recommendation(
    student_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_any_authenticated),
):
    """Rekomendasi belajar adaptif untuk mahasiswa."""
    # RBAC: mahasiswa hanya bisa melihat rekomendasi dirinya sendiri
    if user.role == User.MAHASISWA and user.id != student_id:
        raise HTTPException(
            status_code=403, detail="Anda hanya bisa melihat rekomendasi milik Anda sendiri"
        )
    return get_student_recommendation(db, student_id)
