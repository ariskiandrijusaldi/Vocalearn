from sqlalchemy import Boolean, Column, DateTime, Integer, String, func
from sqlalchemy.orm import relationship

from app.database import Base


class UserRole:
    SUPER_ADMIN = "super_admin"
    DOSEN = "dosen"
    MAHASISWA = "mahasiswa"

    ALL = [SUPER_ADMIN, DOSEN, MAHASISWA]


class User(Base):
    __tablename__ = "users"

    SUPER_ADMIN = UserRole.SUPER_ADMIN
    DOSEN = UserRole.DOSEN
    MAHASISWA = UserRole.MAHASISWA

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(120), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(150), nullable=False)
    role = Column(String(20), nullable=False, default=UserRole.MAHASISWA)
    nim = Column(String(20), nullable=True, unique=True)
    nip = Column(String(20), nullable=True, unique=True)
    prodi = Column(String(120), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)

    created_modules = relationship(
        "Module",
        back_populates="creator",
        foreign_keys="Module.created_by",
    )
    interactions = relationship("Interaction", back_populates="student")
    enrollments = relationship("Enrollment", back_populates="student")
