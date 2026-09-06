from app.models.answer_explanation import AnswerExplanation
from app.models.chat_message import ChatMessage
from app.models.course import Course
from app.models.diagnostic_result import DiagnosticResult
from app.models.enrollment import Enrollment
from app.models.interaction import Interaction
from app.models.kelas import Kelas
from app.models.module import Module, ModuleStatus
from app.models.prodi import Prodi
from app.models.jurusan import Jurusan
from app.models.quiz_attempt import QuizAttempt
from app.models.quiz_question import QuizQuestion
from app.models.quiz_result import QuizResult
from app.models.simplified_material import SimplifiedMaterial
from app.models.user import User, UserRole

__all__ = [
    "AnswerExplanation",
    "ChatMessage",
    "Course",
    "DiagnosticResult",
    "Enrollment",
    "Interaction",
    "Kelas",
    "Module",
    "ModuleStatus",
    "Prodi",
    "Jurusan",
    "QuizAttempt",
    "QuizQuestion",
    "QuizResult",
    "SimplifiedMaterial",
    "User",
    "UserRole",
]
