"""Komposisi rekomendasi belajar adaptif.

Merangkai risk assessment, perhitungan mastery/kompetensi, penentuan modul
berikutnya, dan saran personal Gemini menjadi satu respon RecommendationOut.
"""
from datetime import datetime

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.ai import risk as risk_service
from app.ai.advice import generate_ai_suggestion
from app.ai.scheduler import compute_module_mastery, recommend_next_module
from app.models import Module, User
from app.schemas import CompetencyOut, RecommendationOut, RiskOut


def get_student_recommendation(db: Session, student_id: int) -> RecommendationOut:
    student = db.get(User, student_id)
    if student is None or student.role != User.MAHASISWA:
        raise HTTPException(status_code=404, detail="Mahasiswa tidak ditemukan")

    risk = risk_service.assess_risk(db, student_id)

    mastery_map = compute_module_mastery(db, student_id)
    competencies: list[CompetencyOut] = []
    for module_id, info in mastery_map.items():
        mod = db.get(Module, module_id)
        if mod is None:
            continue
        competencies.append(
            CompetencyOut(
                module_id=module_id,
                module_title=mod.title,
                course_id=mod.course_id,
                mastery=round(info["mastery"], 4),
                attempts=info["attempts"],
            )
        )
    competencies.sort(key=lambda c: c.mastery)

    next_module, reason = recommend_next_module(db, student_id)

    ai_suggestion = generate_ai_suggestion(
        student_id=student_id,
        risk_level=risk["level"],
        average_score=round(risk["average_score"], 1),
        attempt_count=risk["attempt_count"],
        next_module_title=next_module.title if next_module else None,
        reason=reason,
        weakest_module_title=competencies[0].module_title if competencies else None,
    )

    return RecommendationOut(
        student_id=student_id,
        generated_at=datetime.now(),
        risk=RiskOut(**risk),
        competencies=competencies,
        next_module=next_module,
        reason=reason,
        ai_suggestion=ai_suggestion,
    )
