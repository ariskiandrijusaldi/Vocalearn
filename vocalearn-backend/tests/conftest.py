import os

# Harus di-set SEBELUM mengimpor app.* agar config.py membacanya.
# Test memakai DB SQLite terpisah dan tanpa memanggil Gemini sungguhan.
os.environ["DATABASE_URL"] = "sqlite:///./test_vocalearn.db"
os.environ["GEMINI_API_KEY"] = ""
os.environ["JWT_SECRET"] = "test-only-secret-0123456789abcdefghijklmnopqrstuvwxyz"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402
from app.seed import seed  # noqa: E402

TEST_DB = "test_vocalearn.db"


@pytest.fixture(scope="session")
def client():
    if os.path.exists(TEST_DB):
        os.remove(TEST_DB)
    # Context manager memicu lifespan (startup) -> init_db() membuat tabel.
    with TestClient(app) as c:
        seed()  # data demo idempotent: admin, dosen, mahasiswa1-5, dll.
        yield c
