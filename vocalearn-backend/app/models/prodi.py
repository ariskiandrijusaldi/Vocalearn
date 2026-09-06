from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import relationship

from app.database import Base


class Prodi(Base):
    __tablename__ = "prodi"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), unique=True, nullable=False, index=True)
    jurusan_id = Column(
        Integer,
        ForeignKey("jurusans.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    jurusan = relationship("Jurusan", back_populates="prodi")