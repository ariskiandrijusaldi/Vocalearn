"""Papan peringkat (leaderboard) mahasiswa.

Untuk role mahasiswa: menampilkan seluruh mahasiswa sekelas (kelas yang sama),
diurutkan dari rata-rata skor tertinggi ke terendah. Mahasiswa yang belum punya
progres (belum mengerjakan interaksi/kuis apa pun) tetap muncul di daftar dengan
rank None, yang ditampilkan sebagai "-" oleh aplikasi. Mahasiswa tidak dapat
melihat peringkat kelas lain. Admin/dosen hanya melihat mahasiswa yang aktif.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_any_authenticated
from app.models import Interaction, QuizResult, User
from app.schemas import LeaderboardEntry

router = APIRouter(prefix="/leaderboard", tags=["Papan Peringkat"])


@router.get("", response_model=list[LeaderboardEntry])
def get_leaderboard(
    db: Session = Depends(get_db),
    user: User = Depends(require_any_authenticated),
):
    """Ranking mahasiswa yang mengikuti modul (tertinggi ke terendah).

    Mahasiswa hanya melihat peringkat di kelasnya sendiri. Mahasiswa tanpa
    progres tetap muncul namun tanpa nomor peringkat (rank None).
    """
    # Kumpulkan skor per mahasiswa (dari Interaction dan QuizResult).
    scores: dict[int, list[float]] = {}

    interactions = db.query(
        Interaction.student_id, Interaction.score
    ).all()
    for student_id, score in interactions:
        scores.setdefault(student_id, []).append(float(score))

    quiz_results = db.query(
        QuizResult.student_id, QuizResult.skor
    ).all()
    for student_id, skor in quiz_results:
        scores.setdefault(student_id, []).append(float(skor))

    # Mahasiswa melihat seluruh teman sekelas, termasuk yang belum punya progres.
    if user.role == User.MAHASISWA:
        students_q = db.query(User).filter(
            User.role == User.MAHASISWA,
            User.kelas_id == user.kelas_id,
        )
    else:
        # Role lain (admin/dosen) hanya melihat mahasiswa yang punya aktivitas.
        if not scores:
            return []
        students_q = db.query(User).filter(
            User.role == User.MAHASISWA,
            User.id.in_(list(scores.keys())),
        )

    students = students_q.all()

    entries = []
    for student in students:
        raw = scores.get(student.id, [])
        avg = sum(raw) / len(raw) if raw else 0.0
        entries.append(
            LeaderboardEntry(
                rank=None,  # diisi setelah sort untuk yang punya progres
                student_id=student.id,
                full_name=student.full_name,
                nim=student.nim,
                kelas_name=student.kelas.name if student.kelas else None,
                average_score=round(avg, 2),
                attempt_count=len(raw),
            )
        )

    # Yang punya progres diurutkan dari rata-rata tertinggi ke terendah;
    # yang belum punya progres diletakkan di bagian bawah tanpa peringkat.
    active = [e for e in entries if e.attempt_count > 0]
    inactive = [e for e in entries if e.attempt_count == 0]

    active.sort(key=lambda e: (e.average_score, e.full_name or ""), reverse=True)
    inactive.sort(key=lambda e: (e.full_name or "").lower())

    for i, entry in enumerate(active, start=1):
        entry.rank = i

    return active + inactive
