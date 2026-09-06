from app.schemas.admin import (
    AdminStats,
    DailyActivity,
    JurusanStat,
    ModuleStatusCount,
    RoleCount,
)
from app.schemas.ai import (
    AnswerExplanationOut,
    ChatHistoryOut,
    ChatMessageOut,
    ChatSendRequest,
    DiagnosticResultOut,
    DiagnosticSubmitRequest,
    ExplainRequest,
    QuizAttemptOut,
    QuizGenerateRequest,
    QuizQuestionOut,
    QuizSubmitRequest,
    SimplifyMaterialOut,
    SimplifyMaterialRequest,
)
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse
from app.schemas.common import ORMBase
from app.schemas.course import CourseBase, CourseCreate, CourseOut, CourseUpdate
from app.schemas.dosen_leaderboard import DosenRankEntry, DosenRankGroup
from app.schemas.interaction import InteractionCreate, InteractionOut
from app.schemas.kelas import KelasCreate, KelasOut, KelasUpdate
from app.schemas.jurusan import (
    JurusanCreate,
    JurusanOut,
    JurusanUpdate,
    ProdiCreate,
    ProdiOut,
    ProdiUpdate,
)
from app.schemas.leaderboard import LeaderboardEntry
from app.schemas.module import ModuleCreate, ModuleOut, ModuleReview, ModuleUpdate
from app.schemas.recommendation import CompetencyOut, RecommendationOut, RiskOut
from app.schemas.user import ChangePassword, UserCreate, UserOut, UserUpdate

__all__ = [
    "AdminStats",
    "AnswerExplanationOut",
    "ChangePassword",
    "ChatHistoryOut",
    "ChatMessageOut",
    "ChatSendRequest",
    "CompetencyOut",
    "CourseBase",
    "CourseCreate",
    "CourseOut",
    "CourseUpdate",
    "DailyActivity",
    "DiagnosticResultOut",
    "DiagnosticSubmitRequest",
    "DosenRankEntry",
    "DosenRankGroup",
    "ExplainRequest",
    "InteractionCreate",
    "InteractionOut",
    "JurusanCreate",
    "JurusanOut",
    "JurusanStat",
    "JurusanUpdate",
    "KelasCreate",
    "KelasOut",
    "KelasUpdate",
    "LeaderboardEntry",
    "LoginRequest",
    "ModuleCreate",
    "ModuleOut",
    "ModuleReview",
    "ModuleStatusCount",
    "ModuleUpdate",
    "ORMBase",
    "ProdiCreate",
    "ProdiOut",
    "ProdiUpdate",
    "QuizAttemptOut",
    "QuizGenerateRequest",
    "QuizQuestionOut",
    "QuizSubmitRequest",
    "RecommendationOut",
    "RegisterRequest",
    "RiskOut",
    "RoleCount",
    "SimplifyMaterialOut",
    "SimplifyMaterialRequest",
    "TokenResponse",
    "UserCreate",
    "UserOut",
    "UserUpdate",
]
