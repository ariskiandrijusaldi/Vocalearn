from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, func

from app.database import Base


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    role = Column(String(10), nullable=False)  # "user" atau "assistant"
    pesan = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
