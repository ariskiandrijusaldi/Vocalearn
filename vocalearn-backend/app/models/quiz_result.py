from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, func
from sqlalchemy.orm import relationship

from app.database import Base


class QuizResult(Base):
    __tablename__ = "quiz_results"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    material_id = Column(
        Integer, ForeignKey("modules.id", ondelete="CASCADE"), nullable=False, index=True
    )
    skor = Column(Integer, nullable=False)  # 0-100
    total_soal = Column(Integer, nullable=False)
    jawaban_benar = Column(Integer, nullable=False)
    dikuasai = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    student = relationship("User")
    material = relationship("Module")

    @property
    def material_title(self) -> str | None:
        return self.material.title if self.material else None
