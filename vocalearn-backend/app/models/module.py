from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import relationship

from app.database import Base


class ModuleStatus:
    DRAFT = "draft"
    REVIEW = "review"
    PUBLISHED = "published"

    ALL = [DRAFT, REVIEW, PUBLISHED]


class Module(Base):
    __tablename__ = "modules"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(
        Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    content = Column(Text, nullable=True)
    difficulty = Column(Integer, default=1)  # 1..5
    order_index = Column(Integer, default=0)
    status = Column(String(20), default=ModuleStatus.DRAFT, index=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    reviewed_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    review_note = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )
    published_at = Column(DateTime, nullable=True)

    course = relationship("Course", back_populates="modules")
    creator = relationship(
        "User",
        back_populates="created_modules",
        foreign_keys="Module.created_by",
    )
    reviewer = relationship("User", foreign_keys="Module.reviewed_by")
    interactions = relationship("Interaction", back_populates="module")
