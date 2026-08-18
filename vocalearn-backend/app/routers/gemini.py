import os

from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from google import genai
from pydantic import BaseModel

load_dotenv()

router = APIRouter(tags=["AI Gemini"])

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
MODEL_NAME = "models/gemini-flash-latest"

client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None

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
    "Sesuaikan tingkat kesulitan soal dengan level yang diberikan."
)

ROLE_EXPLAIN_WRONG_ANSWER = (
    "Kamu adalah tutor yang membantu siswa memahami kesalahannya di Vocalearn. "
    "Siswa baru saja menjawab salah pada suatu soal. Jelaskan dengan sabar "
    "kenapa jawaban siswa itu salah, apa jawaban yang benar, dan berikan "
    "1 tips singkat supaya siswa tidak mengulangi kesalahan yang sama. "
    "Gunakan nada yang mendukung, jangan membuat siswa merasa bodoh."
)

ROLE_CHAT_TUTOR = (
    "Kamu adalah AI Tutor Bahasa di aplikasi Vocalearn. Bantu siswa belajar "
    "bahasa asing dengan ramah, sabar, dan interaktif. Jawab hanya pertanyaan "
    "seputar pembelajaran bahasa. Jika ditanya di luar topik itu, arahkan "
    "kembali dengan sopan ke konteks belajar bahasa."
)


class SimplifyRequest(BaseModel):
    materi_asli: str
    topik: str
    nilai_siswa: int


class QuizRequest(BaseModel):
    materi: str
    jumlah_soal: int = 5
    level: str = "pemula"


class ExplainRequest(BaseModel):
    soal: str
    jawaban_siswa: str
    jawaban_benar: str


class ChatRequest(BaseModel):
    pesan: str


@router.get("/test-ai")
def test_ai():
    if client is None:
        raise HTTPException(status_code=503, detail="GEMINI_API_KEY belum di-set")
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents="Jawab singkat 1 kalimat: Katakan 'AI Vocalearn Berhasil Terhubung!'",
        )
        return {"status": "success", "respon_ai": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error AI: {str(e)}")


@router.post("/simplify-material")
def simplify_material(req: SimplifyRequest):
    if client is None:
        raise HTTPException(status_code=503, detail="GEMINI_API_KEY belum di-set")
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=(
                f"Topik: {req.topik}\n"
                f"Nilai siswa saat ini: {req.nilai_siswa}\n\n"
                f"Materi asli dari dosen:\n{req.materi_asli}\n\n"
                f"Sederhanakan materi di atas."
            ),
            config={"system_instruction": ROLE_SIMPLIFY_MATERIAL},
        )
        return {"status": "success", "materi_sederhana": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/generate-quiz")
def generate_quiz(req: QuizRequest):
    if client is None:
        raise HTTPException(status_code=503, detail="GEMINI_API_KEY belum di-set")
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=f"Materi:\n{req.materi}\n\nBuatkan {req.jumlah_soal} soal pilihan ganda level {req.level}.",
            config={"system_instruction": ROLE_MAKE_QUIZ},
        )
        return {"status": "success", "quiz": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/explain-wrong-answer")
def explain_wrong_answer(req: ExplainRequest):
    if client is None:
        raise HTTPException(status_code=503, detail="GEMINI_API_KEY belum di-set")
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=(
                f"Soal: {req.soal}\n"
                f"Jawaban siswa: {req.jawaban_siswa}\n"
                f"Jawaban benar: {req.jawaban_benar}\n\n"
                f"Jelaskan kesalahan siswa."
            ),
            config={"system_instruction": ROLE_EXPLAIN_WRONG_ANSWER},
        )
        return {"status": "success", "penjelasan": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@router.post("/chat-tutor")
def chat_tutor(req: ChatRequest):
    if client is None:
        raise HTTPException(status_code=503, detail="GEMINI_API_KEY belum di-set")
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=req.pesan,
            config={"system_instruction": ROLE_CHAT_TUTOR},
        )
        return {"status": "success", "respon_ai": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")
