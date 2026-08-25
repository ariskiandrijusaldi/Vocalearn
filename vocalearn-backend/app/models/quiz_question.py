from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import relationship

from app.database import Base


class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    material_id = Column(
        Integer, ForeignKey("modules.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pertanyaan = Column(Text, nullable=False)
    opsi_a = Column(String(300), nullable=False)
    opsi_b = Column(String(300), nullable=False)
    opsi_c = Column(String(300), nullable=False)
    opsi_d = Column(String(300), nullable=False)
    jawaban_benar = Column(String(1), nullable=False)  # A, B, C, atau D
    penjelasan = Column(Text, nullable=True)
    level = Column(String(20), default="pemula")
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    material = relationship("Module")
    attempts = relationship("QuizAttempt", back_populates="question")
