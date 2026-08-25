from sqlalchemy import Column, DateTime, ForeignKey, Integer, Text, UniqueConstraint, func
from sqlalchemy.orm import relationship

from app.database import Base


class SimplifiedMaterial(Base):
    __tablename__ = "simplified_materials"
    __table_args__ = (UniqueConstraint("material_id", "student_id"),)

    id = Column(Integer, primary_key=True, index=True)
    material_id = Column(
        Integer, ForeignKey("modules.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    konten_sederhana = Column(Text, nullable=False)
    generated_at = Column(DateTime, server_default=func.now(), nullable=False)

    material = relationship("Module")
    student = relationship("User")
