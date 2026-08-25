from sqlalchemy import Column, DateTime, ForeignKey, Integer, Text, func
from sqlalchemy.orm import relationship

from app.database import Base


class AnswerExplanation(Base):
    __tablename__ = "answer_explanations"

    id = Column(Integer, primary_key=True, index=True)
    quiz_attempt_id = Column(
        Integer, ForeignKey("quiz_attempts.id", ondelete="CASCADE"), nullable=False, index=True
    )
    penjelasan_ai = Column(Text, nullable=False)
    tips = Column(Text, nullable=True)
    generated_at = Column(DateTime, server_default=func.now(), nullable=False)

    attempt = relationship("QuizAttempt", back_populates="explanation")
