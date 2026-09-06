from pydantic import BaseModel


class DosenRankEntry(BaseModel):
    rank: int
    student_id: int
    full_name: str
    nim: str | None = None
    average_score: float  # rata-rata skor (0-100)
    attempt_count: int


class DosenRankGroup(BaseModel):
    kelas_id: int | None = None
    kelas_name: str
    entries: list[DosenRankEntry]
