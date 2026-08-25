"""Penentu modul belajar berikutnya (adaptive scheduler).

Logika utama:
1. Kandidat = modul PUBLISHED dari mata kuliah yang diambil siswa.
2. Filter: modul yang mastery-nya masih di bawah threshold (default 0.8).
3. Prioritaskan modul yang mastery-nya paling rendah, lalu urutan materi
   (order_index) sebagai tie-breaker, dan hindari modul yang baru saja dikerjakan.
4. Mata kuliah dengan rata-rata performa terendah didahulukan.

Output: (module, reason).
"""
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.ai.competency import weighted_mastery
from app.models import Enrollment, Interaction, Module, ModuleStatus, QuizResult

MASTERY_THRESHOLD = 0.8
AVOID_RECENT_HOURS = 6


def _activity_entries(db: Session, student_id: int) -> dict[int, list[tuple[float, datetime]]]:
    """Kumpulkan aktivitas belajar per modul dari dua sumber:
    Interaction (alur lama) dan QuizResult (kuis AI). Return {module_id: [(skor, waktu)]}."""
    entries: dict[int, list[tuple[float, datetime]]] = {}

    interactions = (
        db.query(Interaction)
        .filter(Interaction.student_id == student_id)
        .order_by(Interaction.created_at.desc())
        .all()
    )
    for it in interactions:
        entries.setdefault(it.module_id, []).append(
            (float(it.score), it.created_at)
        )

    quiz_results = (
        db.query(QuizResult)
        .filter(QuizResult.student_id == student_id)
        .order_by(QuizResult.created_at.desc())
        .all()
    )
    for qr in quiz_results:
        entries.setdefault(qr.material_id, []).append(
            (float(qr.skor), qr.created_at)
        )

    return entries


def compute_module_mastery(db: Session, student_id: int) -> dict[int, dict]:
    """mastery per modul (dari modul yang pernah dikerjakan siswa)."""
    entries = _activity_entries(db, student_id)

    result: dict[int, dict] = {}
    for module_id, items in entries.items():
        items.sort(key=lambda t: t[1], reverse=True)
        mastery = weighted_mastery(
            [score for score, _ in items],
            [ts for _, ts in items],
        )
        result[module_id] = {"mastery": mastery, "attempts": len(items)}
    return result


def recommend_next_module(db: Session, student_id: int) -> tuple[Module | None, str]:
    enrollments = db.query(Enrollment).filter(Enrollment.student_id == student_id).all()
    if not enrollments:
        return None, "Siswa belum terdaftar di mata kuliah mana pun."

    course_ids = [e.course_id for e in enrollments]
    modules = (
        db.query(Module)
        .filter(
            Module.course_id.in_(course_ids),
            Module.status == ModuleStatus.PUBLISHED,
        )
        .all()
    )
    if not modules:
        return None, "Belum ada modul terbit (published) untuk mata kuliah Anda."

    mastery_map = compute_module_mastery(db, student_id)
    recent_cutoff = datetime.now() - timedelta(hours=AVOID_RECENT_HOURS)
    recently_done = {
        i.module_id
        for i in db.query(Interaction).filter(
            Interaction.student_id == student_id,
            Interaction.created_at >= recent_cutoff,
        ).all()
    } | {
        q.material_id
        for q in db.query(QuizResult).filter(
            QuizResult.student_id == student_id,
            QuizResult.created_at >= recent_cutoff,
        ).all()
    }

    candidates: list[tuple[float, Module, str]] = []
    for mod in modules:
        info = mastery_map.get(mod.id)
        mastery = info["mastery"] if info else 0.0
        if mastery >= MASTERY_THRESHOLD:
            continue  # sudah dikuasai
        reason = (
            f"Nilai Anda masih perlu ditingkatkan (mastery {mastery:.0%})."
            if info
            else "Modul ini belum pernah Anda kerjakan."
        )
        candidates.append((mastery, mod, reason))

    if not candidates:
        return None, "Semua modul Anda sudah dikuasai. Istirahat atau naik ke topik baru!"

    # Prioritas: mastery terendah -> order_index terkecil -> bukan baru dikerjakan
    candidates.sort(
        key=lambda c: (c[0], c[1].order_index, c[1].id in recently_done)
    )
    _, best, reason = candidates[0]
    return best, reason
