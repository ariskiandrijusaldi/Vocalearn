from sqlalchemy import Column, DateTime, Integer, String, func
from sqlalchemy.orm import relationship

from app.database import Base


class Jurusan(Base):
    __tablename__ = "jurusans"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    prodi = relationship(
        "Prodi",
        back_populates="jurusan",
        cascade="all, delete-orphan",
        order_by="Prodi.name",
    )