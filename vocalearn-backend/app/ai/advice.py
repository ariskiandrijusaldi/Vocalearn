"""Saran belajar berbahasa Indonesia yang dihasilkan Gemini.

Fungsi ini dipakai endpoint rekomendasi untuk menambah saran personal
berdasarkan data rekomendasi (risiko, mastery, modul selanjutnya).
Tanpa GEMINI_API_KEY fungsi mengembalikan None sehingga endpoint rekomendasi
tetap berjalan normal. Saat key tersedia tapi Gemini error sesaat, dilakukan
retry lalu jatuh ke saran template (fallback) supaya saran selalu muncul.
"""
import logging
import time

from google import genai

from app.config import settings

logger = logging.getLogger(__name__)

_client = (
    genai.Client(api_key=settings.GEMINI_API_KEY)
    if settings.GEMINI_API_KEY
    else None
)

_CACHE_TTL_SECONDS = 30 * 60
_cache: dict[int, tuple[float, str]] = {}

_MAX_ATTEMPTS = 3

_ROLE_TUTOR = (
    "Kamu adalah tutor AI di aplikasi Vocalearn. Berdasarkan data rekomendasi "
    "belajar seorang siswa, berikan saran belajar yang spesifik, memotivasi, "
    "dan mudah dipahami. Gunakan Bahasa Indonesia yang ramah dan santai."
)


def generate_ai_suggestion(
    *,
    student_id: int | None,
    risk_level: str,
    average_score: float,
    attempt_count: int,
    next_module_title: str | None,
    reason: str,
    weakest_module_title: str | None,
) -> str | None:
    """Hasilkan 2-3 kalimat saran belajar untuk siswa.

    Hasil dari Gemini disimpan dalam cache per siswa (TTL 30 menit). Jika
    pemanggilan Gemini gagal setelah beberapa percobaan, digunakan template
    fallback agar saran tetap tampil. Mengembalikan None hanya ketika API key
    tidak di-set.
    """
    if student_id is not None:
        cached = _cache.get(student_id)
        if cached and time.time() - cached[0] < _CACHE_TTL_SECONDS:
            return cached[1]

    if _client is None:
        return None

    last_error: Exception | None = None
    for attempt in range(1, _MAX_ATTEMPTS + 1):
        try:
            response = _client.models.generate_content(
                model=settings.GEMINI_MODEL,
                contents=(
                    "Data rekomendasi belajar siswa:\n"
                    f"- Level risiko: {risk_level}\n"
                    f"- Rata-rata skor: {average_score}/100\n"
                    f"- Jumlah latihan: {attempt_count}\n"
                    f"- Modul terlemah: {weakest_module_title or '-'}\n"
                    f"- Modul selanjutnya: {next_module_title or '-'}\n"
                    f"- Alasan: {reason}\n\n"
                    "Buatkan 2-3 kalimat saran belajar untuk siswa tersebut."
                ),
                config={"system_instruction": _ROLE_TUTOR},
            )
            text = response.text.strip()
            if text:
                if student_id is not None:
                    _cache[student_id] = (time.time(), text)
                return text
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            logger.warning(
                "Gemini saran gagal (percobaan %d/%d) untuk siswa %s: %s",
                attempt,
                _MAX_ATTEMPTS,
                student_id,
                exc,
            )
            if attempt < _MAX_ATTEMPTS:
                time.sleep(0.5 * attempt)

    logger.error(
        "Gemini saran gagal permanen untuk siswa %s; memakai fallback.",
        student_id,
        exc_info=last_error,
    )
    return _fallback_suggestion(
        risk_level=risk_level,
        next_module_title=next_module_title,
        weakest_module_title=weakest_module_title,
    )


def _fallback_suggestion(
    *,
    risk_level: str,
    next_module_title: str | None,
    weakest_module_title: str | None,
) -> str:
    """Template saran lokal saat Gemini tidak bisa diakses (key tetap ada)."""
    target = next_module_title or weakest_module_title or "materi yang sedang dipelajari"
    if risk_level == "high":
        return (
            f'Kamu perlu menambah jam latihan harian. Mulailah dari "{target}" '
            "dan ulangi tiap modul sampai nilaimu stabil di atas 70. Jangan menyerah!"
        )
    if risk_level == "medium":
        return (
            f'Belajarmu cukup baik, tapi masih bisa ditingkatkan. Fokus dulu ke '
            f'"{target}", lalu buat jadwal latihan rutin agar mastery kamu naik.'
        )
    return (
        "Performa belajarmu sudah bagus! Pertahankan ritme belajar harianmu "
        f'dan lanjutkan ke "{target}" untuk menambah kompetensi baru.'
    )
