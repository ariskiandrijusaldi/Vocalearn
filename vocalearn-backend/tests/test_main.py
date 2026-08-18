"""Smoke test endpoint utama.

Menjalankan server FastAPI via TestClient terhadap database SQLite khusus
(test_vocalearn.db) yang di-seed ulang setiap sesi. Tidak membutuhkan
GEMINI_API_KEY (dinonaktifkan di conftest).
"""


def test_root_returns_200(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.json()["message"] == "Server Vocalearn Aktif"


def test_login_admin(client):
    resp = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    )
    assert resp.status_code == 200
    assert resp.json()["access_token"]


def test_admin_users_and_recommendation(client):
    token = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    users = client.get("/admin/users", headers=headers)
    assert users.status_code == 200
    siswa = [u for u in users.json() if u["role"] == "mahasiswa"]
    assert siswa, "seed harus menghasilkan minimal 1 mahasiswa"

    rec = client.get(f"/recommendation/{siswa[0]['id']}", headers=headers)
    assert rec.status_code == 200
    body = rec.json()
    assert body["student_id"] == siswa[0]["id"]
    assert body["risk"]["level"] in ("low", "medium", "high")
    assert body["risk"]["average_score"] >= 0
