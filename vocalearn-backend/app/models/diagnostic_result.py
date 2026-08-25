from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, func

from app.database import Base


class DiagnosticResult(Base):
    __tablename__ = "diagnostic_results"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    kompetensi_skor = Column(Text, nullable=True)  # JSON string: {"grammar": 70, ...}
    gaya_belajar = Column(String(50), nullable=True)  # visual, auditori, kinestetik
    submitted_at = Column(DateTime, server_default=func.now(), nullable=False)
