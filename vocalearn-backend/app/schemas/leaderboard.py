from pydantic import BaseModel


class LeaderboardEntry(BaseModel):
    rank: int | None = None  # None = mahasiswa belum punya progres
    student_id: int
    full_name: str
    nim: str | None = None
    kelas_name: str | None = None
    average_score: float  # rata-rata skor (0-100)
    attempt_count: int
