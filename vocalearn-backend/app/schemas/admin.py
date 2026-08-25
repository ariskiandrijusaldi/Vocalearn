from pydantic import BaseModel


class RoleCount(BaseModel):
    role: str
    count: int


class ModuleStatusCount(BaseModel):
    status: str
    count: int


class DailyActivity(BaseModel):
    date: str
    interactions: int
    avg_score: float


class AdminStats(BaseModel):
    total_users: int
    users_by_role: list[RoleCount]
    total_courses: int
    total_modules: int
    modules_by_status: list[ModuleStatusCount]
    total_interactions: int
    avg_score: float
    daily_activity: list[DailyActivity]
