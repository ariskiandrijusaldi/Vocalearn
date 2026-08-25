"""Prediksi risiko akademik sederhana berbasis threshold.

Level risiko ditentukan kombinasi: rata-rata skor, jumlah percobaan,
dan tren skor terakhir.
"""
from sqlalchemy.orm import Session

from app.models import Interaction, QuizResult

HIGH_AVG = 55.0
MEDIUM_AVG = 70.0
MIN_ATTEMPTS = 3


def assess_risk(db: Session, student_id: int) -> dict:
    # Gabungkan skor dari Interaction (alur lama) dan QuizResult (kuis AI),
    # diurutkan dari yang terbaru.
    entries: list[tuple[object, float]] = [
        (i.created_at, float(i.score))
        for i in db.query(Interaction)
        .filter(Interaction.student_id == student_id)
        .all()
    ] + [
        (q.created_at, float(q.skor))
        for q in db.query(QuizResult)
        .filter(QuizResult.student_id == student_id)
        .all()
    ]
    entries.sort(key=lambda t: t[0], reverse=True)

    if not entries:
        return {
            "level": "low",
            "average_score": 0.0,
            "attempt_count": 0,
            "reasons": ["Belum ada aktivitas belajar — mulailah dengan modul pertama."],
        }

    scores = [score for _, score in entries]
    avg = sum(scores) / len(scores)
    reasons: list[str] = []

    recent = scores[:3]
    if len(scores) >= 2 and recent[0] < recent[-1]:
        reasons.append("Skor terakhir cenderung menurun.")
    if len(scores) >= MIN_ATTEMPTS and avg < HIGH_AVG:
        reasons.append(f"Rata-rata nilai rendah ({avg:.0f}/100) dari {len(scores)} latihan.")
    if len(scores) < MIN_ATTEMPTS:
        reasons.append("Data latihan masih sedikit, pantau terus.")

    if len(scores) >= MIN_ATTEMPTS and avg < HIGH_AVG:
        level = "high"
    elif avg < MEDIUM_AVG or len(scores) < MIN_ATTEMPTS:
        level = "medium"
    else:
        level = "low"

    if level == "low":
        reasons.append("Performa stabil dan baik. Pertahankan ritme belajarmu!")

    return {
        "level": level,
        "average_score": round(avg, 2),
        "attempt_count": len(scores),
        "reasons": reasons,
    }
