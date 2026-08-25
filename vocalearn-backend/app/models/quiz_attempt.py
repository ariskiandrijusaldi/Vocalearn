from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import relationship

from app.database import Base


class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    question_id = Column(
        Integer, ForeignKey("quiz_questions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    jawaban_siswa = Column(String(1), nullable=False)  # A, B, C, atau D
    is_correct = Column(Boolean, nullable=False)
    answered_at = Column(DateTime, server_default=func.now(), nullable=False)

    student = relationship("User")
    question = relationship("QuizQuestion", back_populates="attempts")
    explanation = relationship("AnswerExplanation", back_populates="attempt", uselist=False)
