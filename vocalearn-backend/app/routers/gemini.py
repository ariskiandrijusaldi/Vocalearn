"""Router AI Gemini — 4 fitur utama dengan persistensi DB.

Endpoints:
  POST /ai/simplify-material     — menyederhanakan materi
  GET  /ai/simplified-material/{material_id}     — ambil rangkuman milik user (null jika belum ada)
  GET  /ai/simplified-material/{material_id}/pdf — rangkuman sebagai unduhan PDF
  POST /ai/generate-quiz         — membuat soal pilihan ganda (JSON)
  POST /ai/explain-wrong-answer  — menjelaskan jawaban salah
  POST /ai/chat-tutor            — chat tutor bahasa (rate-limited)
  GET  /ai/chat-history/{student_id} — riwayat chat
  POST /ai/diagnostic            — submit hasil diagnostic
  GET  /ai/test-ai               — test koneksi Gemini
"""
import json
import logging
import os
import re
import time
from collections import defaultdict
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Response
from fpdf import FPDF
from google import genai
from pypdf import PdfReader
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.deps import get_current_user
from app.models import Module, User
from app.models.answer_explanation import AnswerExplanation
from app.models.chat_message import ChatMessage
from app.models.diagnostic_result import DiagnosticResult
from app.models.quiz_attempt import QuizAttempt
from app.models.quiz_question import QuizQuestion
from app.models.quiz_result import QuizResult
from app.models.simplified_material import SimplifiedMaterial
from app.schemas.ai import (
    AnswerExplanationOut,
    ChatHistoryOut,
    ChatMessageOut,
    ChatSendRequest,
    DiagnosticResultOut,
    DiagnosticSubmitRequest,
    ExplainRequest,
    QuizAttemptDetailOut,
    QuizAttemptOut,
    QuizGenerateRequest,
    QuizQuestionOut,
    QuizResultCreate,
    QuizResultOut,
    QuizSubmitRequest,
    SimplifyMaterialOut,
    SimplifyMaterialRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai", tags=["AI Gemini"])

# ---------------------------------------------------------------------------
# Gemini client
# ---------------------------------------------------------------------------
client = genai.Client(api_key=settings.GEMINI_API_KEY) if settings.GEMINI_API_KEY else None
MODEL_NAME = settings.GEMINI_MODEL

# ---------------------------------------------------------------------------
# Role prompts
# ---------------------------------------------------------------------------
ROLE_SIMPLIFY_MATERIAL = (
    "Kamu adalah asisten pengajar di Vocalearn. Tugasmu HANYA menyederhanakan "
    "materi yang diberikan dosen, TANPA mengubah isi/kontennya. "
    "Gunakan bahasa yang lebih mudah, tambahkan contoh konkret, "
    "dan pecah konsep rumit jadi poin-poin kecil yang mudah dicerna. "
    "Sasaranmu adalah siswa yang baru saja mendapat nilai rendah pada topik ini."
)

ROLE_MAKE_QUIZ = (
    "Kamu adalah pembuat soal latihan di Vocalearn. Berdasarkan materi yang "
    "diberikan, buatkan soal pilihan ganda sebanyak jumlah yang diminta. "
    "Setiap soal harus punya 4 pilihan jawaban (A-D), tandai jawaban benar, "
    "dan beri penjelasan singkat kenapa jawaban itu benar. "
    "Sesuaikan tingkat kesulitan soal dengan level yang diberikan.\n\n"
    "PENTING: Jawab HANYA dalam format JSON array valid, tanpa markdown atau "
    "teks tambahan. Setiap elemen array adalah object dengan key:\n"
    '  "pertanyaan" (string), "opsi_a" (string), "opsi_b" (string), '
    '"opsi_c" (string), "opsi_d" (string), "jawaban_benar" (string "A"/"B"/"C"/"D"), '
    '"penjelasan" (string).\n'
    "Contoh: [{\"pertanyaan\":\"...\",\"opsi_a\":\"...\",\"opsi_b\":\"...\","
    "\"opsi_c\":\"...\",\"opsi_d\":\"...\",\"jawaban_benar\":\"A\","
    "\"penjelasan\":\"...\"}]"
)

ROLE_EXPLAIN_WRONG_ANSWER = (
    "Kamu adalah tutor yang membantu siswa memahami kesalahannya di Vocalearn. "
    "Siswa baru saja menjawab salah pada suatu soal. Jelaskan dengan sabar "
    "kenapa jawaban siswa itu salah, apa jawaban yang benar, dan berikan "
    "1 tips singkat supaya siswa tidak mengulangi kesalahan yang sama. "
    "Gunakan nada yang mendukung, jangan membuat siswa merasa bodoh."
)

ROLE_CHAT_TUTOR = (
    "Kamu adalah Asisten Belajar VocaLearn — pendamping belajar yang ramah, "
    "sabar, dan suportif untuk mahasiswa vokasi.\n\n"
    "ATURAN UTAMA:\n"
    '1. Jawab SETIAP pertanyaan yang diberikan mahasiswa, apapun topiknya '
    '(matematika, jaringan, pemrograman, umum, dll). JANGAN PERNAH membalas '
    'dengan "tidak ada jawaban", "maaf saya tidak tahu", atau menolak menjawab.\n'
    "2. Jika pertanyaan di luar bidang teknis/vokasi (mis. pengetahuan umum), "
    "tetap jawab dengan baik dan akurat sesuai pengetahuanmu.\n"
    "3. Jika pertanyaan ambigu atau kurang jelas, JANGAN menolak — berikan "
    "jawaban terbaik berdasarkan interpretasi paling masuk akal, lalu tawarkan "
    "untuk memperjelas jika perlu.\n"
    "4. Jika benar-benar tidak yakin dengan jawabannya, katakan dengan jujur "
    "bagian mana yang kamu kurang yakin, TAPI tetap berikan penjelasan "
    "sebaik mungkin — jangan kosongkan jawaban.\n"
    "5. Gunakan bahasa Indonesia yang jelas dan mudah dipahami mahasiswa "
    "vokasi. Boleh pakai contoh sederhana atau analogi untuk konsep yang rumit.\n"
    "6. Jawaban ringkas tapi lengkap — jangan bertele-tele, tapi jangan juga "
    "terlalu singkat sampai tidak menjawab pertanyaan.\n"
    '7. Untuk pertanyaan matematika/sains seperti "Fungsi cos adalah...", '
    "jelaskan definisi, rumus dasar, dan contoh penggunaannya secara singkat.\n"
    "8. Jika konteks modul disediakan dan relevan dengan pertanyaan, gunakan "
    "materi modul tersebut sebagai sumber utama jawaban."
)

# ---------------------------------------------------------------------------
# Retry helper
# ---------------------------------------------------------------------------
_MAX_ATTEMPTS = 4

_UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads", "modules")


def _is_quota_error(exc: Exception) -> bool:
    text = str(exc)
    return "429" in text or "RESOURCE_EXHAUSTED" in text


def _is_overloaded_error(exc: Exception) -> bool:
    """Model Gemini sedang sibuk (503/UNAVAILABLE/overloaded)."""
    text = str(exc)
    return (
        "503" in text
        or "UNAVAILABLE" in text
        or "overloaded" in text.lower()
        or "529" in text
    )


def _extract_pdf_text(pdf_path: str | None, max_chars: int = 6000) -> str:
    """Ekstrak teks dari PDF modul (dibatasi panjang agar prompt efisien)."""
    if not pdf_path:
        return ""
    filepath = os.path.join(_UPLOAD_DIR, os.path.basename(pdf_path))
    if not os.path.isfile(filepath):
        return ""
    try:
        reader = PdfReader(filepath)
        text = "\n".join((page.extract_text() or "") for page in reader.pages)
        return text.strip()[:max_chars]
    except Exception as exc:
        logger.warning("Gagal ekstrak PDF %s: %s", pdf_path, exc)
        return ""


def _material_source(module: Module, max_chars: int = 6000) -> str:
    """Sumber materi terbaik untuk AI: konten -> teks PDF -> deskripsi -> judul."""
    if module.content:
        return module.content[:max_chars]
    pdf_text = _extract_pdf_text(module.pdf_path, max_chars)
    if pdf_text:
        return pdf_text
    return module.description or module.title or ""


def _chat_module_context(module: Module) -> str:
    """Konteks lengkap untuk chat tutor: deskripsi + konten + teks PDF digabung.

    Untuk pertanyaan mendalam, tutor perlu melihat semua sumber materi,
    bukan hanya satu sumber prioritas.
    """
    bagian: list[str] = [f"Judul: {module.title}"]
    if module.description:
        bagian.append(f"Deskripsi: {module.description[:500]}")
    if module.content:
        bagian.append(f"Konten modul:\n{module.content[:7000]}")
    pdf_text = _extract_pdf_text(module.pdf_path, max_chars=7000)
    if pdf_text:
        bagian.append(f"Isi file PDF terlampir:\n{pdf_text}")
    if module.youtube_url:
        bagian.append(
            "Catatan: modul ini memiliki video YouTube terkait "
            "(isi video tidak tersedia bagi tutor)."
        )
    return "\n\n".join(bagian)


def _call_gemini(prompt: str, *, system_instruction: str, response_mime_type: str | None = None) -> str:
    """Panggil Gemini dengan retry + backoff. Raise HTTPException kalau gagal."""
    if client is None:
        raise HTTPException(status_code=503, detail="GEMINI_API_KEY belum di-set")

    config: dict = {"system_instruction": system_instruction}
    if response_mime_type:
        config["response_mime_type"] = response_mime_type

    last_error: Exception | None = None
    for attempt in range(1, _MAX_ATTEMPTS + 1):
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
                config=config,
            )
            text = (response.text or "").strip()
            if text:
                return text
        except Exception as exc:
            last_error = exc
            # Kuota free tier per menit (429): retry cepat hanya membuang waktu.
            if _is_quota_error(exc):
                logger.warning("Kuota Gemini habis: %s", exc)
                raise HTTPException(
                    status_code=429,
                    detail=(
                        "Kuota Gemini free tier habis (batas permintaan/menit). "
                        "Tunggu sekitar 1 menit lalu coba lagi."
                    ),
                )
            logger.warning(
                "Gemini gagal (percobaan %d/%d): %s", attempt, _MAX_ATTEMPTS, exc
            )
            if attempt < _MAX_ATTEMPTS:
                # Overload butuh backoff lebih panjang; error lain cukup cepat.
                delay = 2.5 * attempt if _is_overloaded_error(exc) else 0.5 * attempt
                time.sleep(delay)

    if last_error is not None and _is_overloaded_error(last_error):
        raise HTTPException(
            status_code=503,
            detail=(
                "Server AI sedang sibuk (lonjakan permintaan). "
                "Coba lagi 1-2 menit lagi, atau ganti GEMINI_MODEL di .env."
            ),
        )
    raise HTTPException(
        status_code=502,
        detail=f"Gemini API gagal setelah {_MAX_ATTEMPTS} percobaan: {last_error}",
    )


# ---------------------------------------------------------------------------
# Rate limiting (per-user, in-memory, untuk chat-tutor)
# ---------------------------------------------------------------------------
_chat_rate: dict[int, list[float]] = defaultdict(list)
_CHAT_RATE_LIMIT = 10  # max requests
_CHAT_RATE_WINDOW = 60.0  # detik


def _check_chat_rate(student_id: int) -> None:
    now = time.time()
    _chat_rate[student_id] = [
        t for t in _chat_rate[student_id] if now - t < _CHAT_RATE_WINDOW
    ]
    if len(_chat_rate[student_id]) >= _CHAT_RATE_LIMIT:
        raise HTTPException(
            status_code=429,
            detail="Terlalu banyak permintaan chat. Coba lagi dalam beberapa saat.",
        )
    _chat_rate[student_id].append(now)


# ---------------------------------------------------------------------------
# GET /ai/test-ai
# ---------------------------------------------------------------------------
@router.get("/test-ai")
def test_ai(user: User = Depends(get_current_user)):
    text = _call_gemini(
        "Jawab singkat 1 kalimat: Katakan 'AI Vocalearn Berhasil Terhubung!'",
        system_instruction="Kamu adalah asisten AI di Vocalearn.",
    )
    return {"status": "success", "respon_ai": text}


# ---------------------------------------------------------------------------
# Rangkuman: ambil + unduh PDF
# ---------------------------------------------------------------------------
def _build_rangkuman_pdf(judul: str, konten: str) -> bytes:
    """Rangkuman sederhana jadi PDF A4.

    Font core helvetica hanya mendukung latin-1, jadi karakter di luar itu
    diganti agar generate tidak error.
    """
    pdf = FPDF(format="A4")
    pdf.set_auto_page_break(auto=True, margin=18)
    pdf.add_page()

    # fpdf2 memindahkan X ke kanan setelah multi_cell — reset ke margin kiri
    # agar cell berikutnya tetap punya ruang penuh.
    pdf.set_x(pdf.l_margin)
    pdf.set_font("helvetica", "B", 15)
    pdf.multi_cell(
        0,
        9,
        "Rangkuman Mudah Dipahami".encode("latin-1", "replace").decode("latin-1"),
    )
    pdf.set_x(pdf.l_margin)
    pdf.set_font("helvetica", "", 11)
    pdf.multi_cell(0, 7, judul.encode("latin-1", "replace").decode("latin-1"))
    pdf.ln(3)
    pdf.set_draw_color(180)
    pdf.line(pdf.l_margin, pdf.get_y(), pdf.w - pdf.r_margin, pdf.get_y())
    pdf.ln(5)

    pdf.set_x(pdf.l_margin)
    pdf.set_font("helvetica", "", 11)
    pdf.multi_cell(0, 6, konten.encode("latin-1", "replace").decode("latin-1"))
    return bytes(pdf.output())


def _nama_file_pdf(judul: str, material_id: int) -> str:
    bersih = re.sub(r"[^A-Za-z0-9]+", "_", judul).strip("_") or f"modul_{material_id}"
    return f"rangkuman_{bersih.lower()[:40]}.pdf"


@router.get("/simplified-material/{material_id}")
def get_simplified_material(
    material_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> SimplifyMaterialOut | None:
    """Rangkuman milik user yang sedang login; null jika belum pernah dibuat."""
    return (
        db.query(SimplifiedMaterial)
        .filter(
            SimplifiedMaterial.material_id == material_id,
            SimplifiedMaterial.student_id == user.id,
        )
        .first()
    )


@router.get("/simplified-material/{material_id}/pdf")
def download_simplified_material_pdf(
    material_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """PDF rangkuman untuk diunduh — dibuat on-the-fly dari konten tersimpan."""
    simplified = (
        db.query(SimplifiedMaterial)
        .filter(
            SimplifiedMaterial.material_id == material_id,
            SimplifiedMaterial.student_id == user.id,
        )
        .first()
    )
    if not simplified:
        raise HTTPException(
            status_code=404,
            detail="Rangkuman belum tersedia. Kerjakan kuis dengan nilai rendah dulu.",
        )
    module = db.get(Module, material_id)
    judul = module.title if module else f"Modul {material_id}"
    data = _build_rangkuman_pdf(judul=judul, konten=simplified.konten_sederhana)
    filename = _nama_file_pdf(judul, material_id)
    return Response(
        content=data,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# ---------------------------------------------------------------------------
# POST /ai/simplify-material
# ---------------------------------------------------------------------------
@router.post("/simplify-material", response_model=SimplifyMaterialOut)
def simplify_material(
    req: SimplifyMaterialRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    material = db.get(Module, req.material_id)
    if not material:
        raise HTTPException(status_code=404, detail="Materi tidak ditemukan")

    existing = (
        db.query(SimplifiedMaterial)
        .filter(
            SimplifiedMaterial.material_id == req.material_id,
            SimplifiedMaterial.student_id == req.student_id,
        )
        .first()
    )
    if existing:
        return existing

    content = _material_source(material)
    prompt = (
        f"Topik: {material.title}\n\n"
        f"Materi asli dari dosen:\n{content}\n\n"
        f"Sederhanakan materi di atas."
    )
    result = _call_gemini(prompt, system_instruction=ROLE_SIMPLIFY_MATERIAL)

    simplified = SimplifiedMaterial(
        material_id=req.material_id,
        student_id=req.student_id,
        konten_sederhana=result,
    )
    db.add(simplified)
    db.commit()
    db.refresh(simplified)
    return simplified


# ---------------------------------------------------------------------------
# POST /ai/generate-quiz
# ---------------------------------------------------------------------------
@router.post("/generate-quiz", response_model=list[QuizQuestionOut])
def generate_quiz(
    req: QuizGenerateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    material = db.get(Module, req.material_id)
    if not material:
        raise HTTPException(status_code=404, detail="Materi tidak ditemukan")

    content = _material_source(material)
    prompt = (
        f"Materi:\n{content}\n\n"
        f"Buatkan {req.jumlah_soal} soal pilihan ganda level {req.level}."
    )
    raw = _call_gemini(
        prompt,
        system_instruction=ROLE_MAKE_QUIZ,
        response_mime_type="application/json",
    )

    # Parse JSON — handle markdown code blocks jika ada
    cleaned = re.sub(r"```json\s*|\s*```", "", raw).strip()
    try:
        items = json.loads(cleaned)
    except json.JSONDecodeError:
        # Coba cari array JSON dalam teks
        match = re.search(r"\[.*\]", cleaned, re.DOTALL)
        if match:
            items = json.loads(match.group())
        else:
            raise HTTPException(
                status_code=502,
                detail="Gagal parse respons Gemini sebagai JSON. Coba lagi.",
            )

    saved: list[QuizQuestion] = []
    for item in items[: req.jumlah_soal]:
        q = QuizQuestion(
            material_id=req.material_id,
            pertanyaan=item.get("pertanyaan", ""),
            opsi_a=item.get("opsi_a", ""),
            opsi_b=item.get("opsi_b", ""),
            opsi_c=item.get("opsi_c", ""),
            opsi_d=item.get("opsi_d", ""),
            jawaban_benar=item.get("jawaban_benar", "A"),
            penjelasan=item.get("penjelasan"),
            level=req.level,
        )
        db.add(q)
        db.flush()
        saved.append(q)

    db.commit()
    for q in saved:
        db.refresh(q)
    return saved


# ---------------------------------------------------------------------------
# POST /ai/explain-wrong-answer
# ---------------------------------------------------------------------------
@router.post("/explain-wrong-answer", response_model=AnswerExplanationOut)
def explain_wrong_answer(
    req: ExplainRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    attempt = db.get(QuizAttempt, req.quiz_attempt_id)
    if not attempt:
        raise HTTPException(status_code=404, detail="Quiz attempt tidak ditemukan")
    if attempt.is_correct:
        raise HTTPException(status_code=400, detail="Jawaban ini sudah benar, tidak perlu penjelasan")

    question = db.get(QuizQuestion, attempt.question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Soal tidak ditemukan")

    existing = (
        db.query(AnswerExplanation)
        .filter(AnswerExplanation.quiz_attempt_id == req.quiz_attempt_id)
        .first()
    )
    if existing:
        return existing

    prompt = (
        f"Soal: {question.pertanyaan}\n"
        f"Opsi: A) {question.opsi_a} B) {question.opsi_b} "
        f"C) {question.opsi_c} D) {question.opsi_d}\n"
        f"Jawaban benar: {question.jawaban_benar}\n"
        f"Jawaban siswa: {attempt.jawaban_siswa}\n\n"
        f"Jelaskan kesalahan siswa."
    )
    result = _call_gemini(prompt, system_instruction=ROLE_EXPLAIN_WRONG_ANSWER)

    explanation = AnswerExplanation(
        quiz_attempt_id=req.quiz_attempt_id,
        penjelasan_ai=result,
        tips=None,
    )
    db.add(explanation)
    db.commit()
    db.refresh(explanation)
    return explanation


# ---------------------------------------------------------------------------
# POST /ai/chat-tutor
# ---------------------------------------------------------------------------
@router.post("/chat-tutor", response_model=ChatMessageOut)
def chat_tutor(
    req: ChatSendRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _check_chat_rate(req.student_id)

    user_msg = ChatMessage(
        student_id=req.student_id,
        role="user",
        pesan=req.pesan,
    )
    db.add(user_msg)
    db.flush()

    history = (
        db.query(ChatMessage)
        .filter(ChatMessage.student_id == req.student_id)
        .order_by(ChatMessage.created_at.desc())
        .limit(10)
        .all()
    )
    history.reverse()

    # Konteks modul: tutor menjawab berdasarkan isi modul ini
    # (deskripsi + konten + teks PDF digabung agar bisa menjawab pertanyaan mendalam).
    modul_context = ""
    if req.material_id:
        material = db.get(Module, req.material_id)
        if material:
            modul_context = (
                f"Konteks — modul yang sedang dipelajari siswa:\n"
                f"{_chat_module_context(material)}\n\n"
            )

    context_lines = []
    for msg in history:
        if msg.id == user_msg.id:
            continue
        role_label = "Siswa" if msg.role == "user" else "Tutor"
        context_lines.append(f"{role_label}: {msg.pesan}")
    context_lines.append(f"Siswa: {req.pesan}")

    prompt = (
        modul_context
        + "Riwayat percakapan:\n"
        + "\n".join(context_lines)
        + "\n\nJawab pertanyaan mahasiswa di atas sekarang:"
    )
    reply_text = _call_gemini(prompt, system_instruction=ROLE_CHAT_TUTOR)

    assistant_msg = ChatMessage(
        student_id=req.student_id,
        role="assistant",
        pesan=reply_text,
    )
    db.add(assistant_msg)
    db.commit()
    db.refresh(assistant_msg)
    return assistant_msg


# ---------------------------------------------------------------------------
# GET /ai/chat-history/{student_id}
# ---------------------------------------------------------------------------
@router.get("/chat-history/{student_id}", response_model=ChatHistoryOut)
def chat_history(
    student_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    messages = (
        db.query(ChatMessage)
        .filter(ChatMessage.student_id == student_id)
        .order_by(ChatMessage.created_at.asc())
        .limit(100)
        .all()
    )
    return ChatHistoryOut(messages=messages)


# ---------------------------------------------------------------------------
# POST /ai/quiz-submit
# ---------------------------------------------------------------------------
@router.post("/quiz-submit", response_model=QuizAttemptOut)
def quiz_submit(
    req: QuizSubmitRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    question = db.get(QuizQuestion, req.question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Soal tidak ditemukan")

    is_correct = req.jawaban_siswa.upper() == question.jawaban_benar.upper()
    attempt = QuizAttempt(
        student_id=req.student_id,
        question_id=req.question_id,
        jawaban_siswa=req.jawaban_siswa.upper(),
        is_correct=is_correct,
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)
    return attempt


# ---------------------------------------------------------------------------
# POST /ai/quiz-result — simpan nilai akhir kuis
# ---------------------------------------------------------------------------
@router.post("/quiz-result", response_model=QuizResultOut)
def save_quiz_result(
    req: QuizResultCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    material = db.get(Module, req.material_id)
    if not material:
        raise HTTPException(status_code=404, detail="Materi tidak ditemukan")

    existing = (
        db.query(QuizResult)
        .filter(
            QuizResult.student_id == req.student_id,
            QuizResult.material_id == req.material_id,
        )
        .order_by(QuizResult.created_at.desc())
        .first()
    )

    if existing:
        existing.skor = req.skor
        existing.total_soal = req.total_soal
        existing.jawaban_benar = req.jawaban_benar
        existing.dikuasai = req.dikuasai
        db.commit()
        db.refresh(existing)
        return existing

    result = QuizResult(
        student_id=req.student_id,
        material_id=req.material_id,
        skor=req.skor,
        total_soal=req.total_soal,
        jawaban_benar=req.jawaban_benar,
        dikuasai=req.dikuasai,
    )
    db.add(result)
    db.commit()
    db.refresh(result)
    return result


# ---------------------------------------------------------------------------
# GET /ai/quiz-results/{student_id} — riwayat nilai kuis mahasiswa
# ---------------------------------------------------------------------------
@router.get("/quiz-results/{student_id}", response_model=list[QuizResultOut])
def get_quiz_results(
    student_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    from sqlalchemy.orm import joinedload

    return (
        db.query(QuizResult)
        .options(joinedload(QuizResult.material))
        .filter(QuizResult.student_id == student_id)
        .order_by(QuizResult.created_at.desc())
        .limit(100)
        .all()
    )


# ---------------------------------------------------------------------------
# GET /ai/quiz-attempts/{student_id}/{material_id}
# Riwayat jawaban per soal untuk satu sesi kuis.
# ---------------------------------------------------------------------------
@router.get(
    "/quiz-attempts/{student_id}/{material_id}",
    response_model=list[QuizAttemptDetailOut],
)
def get_quiz_attempts(
    student_id: int,
    material_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # RBAC: mahasiswa hanya boleh melihat jawaban diri sendiri
    if user.role == User.MAHASISWA and user.id != student_id:
        raise HTTPException(
            status_code=403,
            detail="Anda hanya bisa melihat riwayat jawaban sendiri",
        )

    attempts = (
        db.query(QuizAttempt)
        .join(QuizQuestion, QuizAttempt.question_id == QuizQuestion.id)
        .filter(
            QuizAttempt.student_id == student_id,
            QuizQuestion.material_id == material_id,
        )
        .order_by(QuizAttempt.answered_at.desc())
        .all()
    )

    result: list[QuizAttemptDetailOut] = []
    for att in attempts:
        q = att.question
        expl = att.explanation
        result.append(
            QuizAttemptDetailOut(
                attempt_id=att.id,
                question_id=q.id,
                pertanyaan=q.pertanyaan,
                opsi_a=q.opsi_a,
                opsi_b=q.opsi_b,
                opsi_c=q.opsi_c,
                opsi_d=q.opsi_d,
                jawaban_siswa=att.jawaban_siswa,
                jawaban_benar=q.jawaban_benar,
                is_correct=att.is_correct,
                penjelasan=q.penjelasan,
                penjelasan_ai=expl.penjelasan_ai if expl else None,
                tips=expl.tips if expl else None,
                answered_at=att.answered_at,
            )
        )
    return result


# ---------------------------------------------------------------------------
# POST /ai/diagnostic
# ---------------------------------------------------------------------------
@router.post("/diagnostic", response_model=DiagnosticResultOut)
def submit_diagnostic(
    req: DiagnosticSubmitRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # Aturan bisnis: diagnostik hanya boleh diisi SATU KALI per mahasiswa.
    existing = (
        db.query(DiagnosticResult)
        .filter(DiagnosticResult.student_id == req.student_id)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=409,
            detail="Diagnostik hanya bisa diisi sekali. Hasil sebelumnya tetap berlaku.",
        )

    result = DiagnosticResult(
        student_id=req.student_id,
        kompetensi_skor=json.dumps(req.kompetensi_skor),
        gaya_belajar=req.gaya_belajar,
    )
    db.add(result)
    db.commit()
    db.refresh(result)
    return result


# ---------------------------------------------------------------------------
# GET /ai/diagnostic/{student_id} — hasil diagnostik mahasiswa (null jika belum)
# ---------------------------------------------------------------------------
@router.get("/diagnostic/{student_id}", response_model=DiagnosticResultOut | None)
def get_diagnostic(
    student_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return (
        db.query(DiagnosticResult)
        .filter(DiagnosticResult.student_id == student_id)
        .order_by(DiagnosticResult.submitted_at.desc())
        .first()
    )
