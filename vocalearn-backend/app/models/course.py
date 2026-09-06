from sqlalchemy import Column, DateTime, Integer, String, Text, func
from sqlalchemy.orm import relationship

from app.database import Base


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(20), unique=True, index=True, nullable=False)
    name = Column(String(150), nullable=False)
    prodi = Column(String(120), nullable=True)
    semester = Column(Integer, default=1)
    credits = Column(Integer, default=3)
    # Mapping SKKNI / KKNI
    skkni_unit = Column(String(200), nullable=True)
    skkni_code = Column(String(50), nullable=True)
    kkni_level = Column(Integer, default=6)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    modules = relationship(
        "Module",
        back_populates="course",
        cascade="all, delete-orphan",
    )
    enrollments = relationship(
        "Enrollment",
        back_populates="course",
        cascade="all, delete-orphan",
    )
