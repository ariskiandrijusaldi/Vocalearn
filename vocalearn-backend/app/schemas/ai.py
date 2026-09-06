from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.schemas.common import ORMBase


class SimplifyMaterialRequest(BaseModel):
    material_id: int
    student_id: int


class SimplifyMaterialOut(ORMBase):
    id: int
    material_id: int
    student_id: int
    konten_sederhana: str
    generated_at: datetime


class QuizGenerateRequest(BaseModel):
    material_id: int
    jumlah_soal: int = 5
    level: str = "pemula"


class QuizQuestionOut(ORMBase):
    id: int
    material_id: int
    pertanyaan: str
    opsi_a: str
    opsi_b: str
    opsi_c: str
    opsi_d: str
    jawaban_benar: str
    penjelasan: Optional[str] = None
    level: str
    created_at: datetime


class QuizSubmitRequest(BaseModel):
    student_id: int
    question_id: int
    jawaban_siswa: str  # A, B, C, atau D


class QuizAttemptOut(ORMBase):
    id: int
    student_id: int
    question_id: int
    jawaban_siswa: str
    is_correct: bool
    answered_at: datetime


class QuizResultCreate(BaseModel):
    student_id: int
    material_id: int
    skor: int  # 0-100
    total_soal: int
    jawaban_benar: int
    dikuasai: bool = False


class QuizResultOut(ORMBase):
    id: int
    student_id: int
    material_id: int
    material_title: Optional[str] = None
    skor: int
    total_soal: int
    jawaban_benar: int
    dikuasai: bool
    created_at: datetime


class ExplainRequest(BaseModel):
    quiz_attempt_id: int
    student_id: int


class AnswerExplanationOut(ORMBase):
    id: int
    quiz_attempt_id: int
    penjelasan_ai: str
    tips: Optional[str] = None
    generated_at: datetime


class QuizAttemptDetailOut(ORMBase):
    attempt_id: int
    question_id: int
    pertanyaan: str
    opsi_a: str
    opsi_b: str
    opsi_c: str
    opsi_d: str
    jawaban_siswa: str
    jawaban_benar: str
    is_correct: bool
    penjelasan: Optional[str] = None
    penjelasan_ai: Optional[str] = None
    tips: Optional[str] = None
    answered_at: datetime


class ChatSendRequest(BaseModel):
    student_id: int
    pesan: str
    material_id: Optional[int] = None  # konteks modul agar jawaban AI relevan


class ChatMessageOut(ORMBase):
    id: int
    student_id: int
    role: str
    pesan: str
    created_at: datetime


class ChatHistoryOut(BaseModel):
    messages: list[ChatMessageOut]


class DiagnosticSubmitRequest(BaseModel):
    student_id: int
    kompetensi_skor: dict  # {"grammar": 70, "vocabulary": 85, ...}
    gaya_belajar: str  # visual, auditori, kinestetik


class DiagnosticResultOut(ORMBase):
    id: int
    student_id: int
    kompetensi_skor: Optional[str] = None
    gaya_belajar: Optional[str] = None
    submitted_at: datetime
