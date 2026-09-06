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


def test_leaderboard_returns_sorted_mahasiswa(client):
    """Leaderboard menampilkan seluruh mahasiswa yang mengikuti modul,
    diurutkan dari rata-rata skor tertinggi ke terendah."""
    token = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = client.get("/leaderboard", headers=headers)
    assert resp.status_code == 200
    body = resp.json()

    # Harus ada peserta (seed mengisi interaksi beberapa mahasiswa).
    assert body, "leaderboard harus berisi minimal 1 mahasiswa pengikut modul"

    # Urutan menurun berdasarkan rata-rata skor.
    averages = [entry["average_score"] for entry in body]
    assert averages == sorted(averages, reverse=True)

    # Semua entri harus mahasiswa, punya peringkat (rank) unik 1..N.
    ranks = [entry["rank"] for entry in body]
    assert ranks == list(range(1, len(body) + 1))


def test_dosen_leaderboard_grouped_by_class(client):
    """Leaderboard dosen mengelompokkan mahasiswa per kelas dan mengurutkannya
    dari rata-rata skor tertinggi ke terendah. Mahasiswa tanpa progres tidak
    mendapat peringkat (rank None)."""
    token = client.post(
        "/auth/login",
        json={"email": "dosen1@vocalearn.id", "password": "dosen123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = client.get("/dosen/leaderboard", headers=headers)
    assert resp.status_code == 200
    body = resp.json()

    # Harus ada minimal 1 kelompok kelas.
    assert body, "leaderboard dosen harus berisi minimal 1 kelas"

    for group in body:
        assert "kelas_name" in group
        entries = group["entries"]
        assert entries, "tiap kelas harus memiliki mahasiswa"
        # Diurutkan dari rata-rata tertinggi ke terendah (khusus yang aktif).
        active = [e for e in entries if e["attempt_count"] > 0]
        averages = [e["average_score"] for e in active]
        assert averages == sorted(averages, reverse=True)
        # Rank unik 1..N hanya untuk yang punya progres; sisanya rank None.
        active_ranks = [e["rank"] for e in active]
        assert active_ranks == list(range(1, len(active) + 1))
        for e in entries:
            if e["attempt_count"] == 0:
                assert e["rank"] is None


def test_dosen_courses_scoped_to_jurusan(client):
    """Dosen hanya melihat mata kuliah dari jurusan yang ia ampu.
    Seed menetapkan dosen1 ke jurusan Teknologi Informasi, sehingga
    `/courses` hanya memuat MK dengan prodi TI (mis. S1 Teknik Informatika)
    dan tidak memuat MK jurusan lain (mis. S1 Akuntansi)."""
    token = client.post(
        "/auth/login",
        json={"email": "dosen1@vocalearn.id", "password": "dosen123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    courses = client.get("/courses", headers=headers)
    assert courses.status_code == 200
    body = courses.json()
    assert body, "dosen1 harus punya minimal 1 MK dari jurusan TI"

    # Identitas jurusan tampil di /auth/me.
    me = client.get("/auth/me", headers=headers)
    assert me.json()["jurusan_name"] == "Teknologi Informasi"

    # Semua MK milik prodi TI; MK jurusan lain tidak boleh tampil.
    ti_prodi = {"S1 Teknik Informatika", "S1 Sistem Informasi", "Manajemen Informatika"}
    for c in body:
        assert c["prodi"] in ti_prodi, c["prodi"]
    assert not any(c["code"] == "BMAN103" for c in body), "MK Akuntansi tidak boleh tampil"

    # Admin & mahasiswa tetap melihat semua MK.
    admin_token = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    all_courses = client.get(
        "/courses", headers={"Authorization": f"Bearer {admin_token}"}
    ).json()
    assert any(c["code"] == "BMAN103" for c in all_courses)


def test_admin_assigns_dosen_jurusan(client):
    """Super admin menetapkan jurusan untuk dosen via PATCH /admin/users,
    dan daftar MK yang tampil untuk dosen mengikuti jurusan tersebut."""
    token = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Ambil id jurusan "Akuntansi" yang di-seed.
    jurusan = client.get("/jurusan", headers=headers).json()
    akuntansi = next(j for j in jurusan if j["name"] == "Akuntansi")

    # Dosen baru dibuat dengan jurusan Akuntansi.
    created = client.post(
        "/admin/users",
        headers=headers,
        json={
            "email": "dosen.ak@vocalearn.id",
            "password": "dosen123",
            "full_name": "Dosen Akuntansi",
            "role": "dosen",
            "jurusan_id": akuntansi["id"],
        },
    )
    assert created.status_code == 201
    did = created.json()["id"]
    assert created.json()["jurusan_name"] == "Akuntansi"

    # Dosen melihat hanya MK Akuntansi (S1 Akuntansi / D3 Akuntansi).
    d_token = client.post(
        "/auth/login",
        json={"email": "dosen.ak@vocalearn.id", "password": "dosen123"},
    ).json()["access_token"]
    d_head = {"Authorization": f"Bearer {d_token}"}
    ak_courses = client.get("/courses", headers=d_head).json()
    assert ak_courses, "harus ada MK Akuntansi"
    assert all(c["prodi"] in ("S1 Akuntansi", "D3 Akuntansi") for c in ak_courses)
    assert not any(c["code"] == "BING101" for c in ak_courses)

    # Pindahkan dosen ke Teknologi Informasi -> daftar MK ikut berubah.
    ti = next(j for j in jurusan if j["name"] == "Teknologi Informasi")
    moved = client.patch(
        f"/admin/users/{did}",
        headers=headers,
        json={"jurusan_id": ti["id"]},
    )
    assert moved.status_code == 200
    assert moved.json()["jurusan_name"] == "Teknologi Informasi"

    ti_courses = client.get("/courses", headers=d_head).json()
    assert ti_courses
    assert all(
        c["prodi"] in ("S1 Teknik Informatika", "S1 Sistem Informasi", "Manajemen Informatika")
        for c in ti_courses
    )

    # jurusan_id tidak valid -> ditolak.
    bad = client.patch(f"/admin/users/{did}", headers=headers, json={"jurusan_id": 99999})
    assert bad.status_code == 400


def test_dosen_kelas_scoped_to_own_classes(client):
    """Dosen hanya melihat kelas yang ia ajar saat mengunggah materi."""
    d1 = client.post(
        "/auth/login",
        json={"email": "dosen1@vocalearn.id", "password": "dosen123"},
    ).json()["access_token"]
    d1_head = {"Authorization": f"Bearer {d1}"}

    kelas = client.get("/kelas", headers=d1_head)
    assert kelas.status_code == 200
    names = [k["name"] for k in kelas.json()]
    # Seed menetapkan dosen1 ke kelas TI-2A, dosen2 ke TI-2B.
    assert names == ["TI-2A"], names
    assert "TI-2B" not in names

    # Admin tetap melihat semua kelas.
    admin = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    all_names = [
        k["name"]
        for k in client.get(
            "/kelas", headers={"Authorization": f"Bearer {admin}"}
        ).json()
    ]
    assert "TI-2A" in all_names and "TI-2B" in all_names


def test_dosen_create_module_published_directly(client):
    """Dosen dapat langsung mengunggah modul tanpa persetujuan —
    modul langsung berstatus published sehingga terlihat mahasiswa."""
    token = client.post(
        "/auth/login",
        json={"email": "dosen1@vocalearn.id", "password": "dosen123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    courses = client.get("/courses", headers=headers)
    assert courses.status_code == 200
    course_id = courses.json()[0]["id"]

    resp = client.post(
        "/modules",
        headers=headers,
        json={
            "course_id": course_id,
            "title": "Modul Unggah Langsung",
            "description": "Dibuat langsung oleh dosen tanpa review admin",
            "difficulty": 1,
            "order_index": 999,
        },
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["status"] == "published"
    assert body["published_at"] is not None


def test_mahasiswa_leaderboard_scoped_to_own_class(client):
    """Mahasiswa hanya melihat peringkat di kelasnya sendiri, bukan kelas lain."""
    # mahasiswa1 (240001) berada di kelas TI-2A bersama mahasiswa2.
    token = client.post(
        "/auth/login",
        json={"email": "mahasiswa1@vocalearn.id", "password": "siswa123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = client.get("/leaderboard", headers=headers)
    assert resp.status_code == 200
    body = resp.json()

    # Seed mengisi interaksi untuk mahasiswa1 & mahasiswa2 (TI-2A),
    # sehingga minimal 1 peserta dari kelas yang sama.
    assert body, "leaderboard harus berisi peserta sekelas"

    for entry in body:
        # Tidak boleh memuat mahasiswa dari kelas lain.
        assert entry["kelas_name"] == "TI-2A"

    # Pastikan mahasiswa dari kelas lain (TI-2B) tidak muncul.
    # 240004 (Budi, TI-2B) dan Sinta (TI-2B) tidak boleh ada.
    assert not any(e["nim"] == "240004" for e in body)
    assert not any("Sinta" in e["full_name"] for e in body)


def test_admin_update_course(client):
    """Super admin dapat mengedit mata kuliah, termasuk kolom prodi."""
    token = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    created = client.post(
        "/courses",
        headers=headers,
        json={
            "code": "TEST101",
            "name": "Kursus Uji",
            "prodi": "S1 Bahasa Inggris",
            "semester": 1,
            "credits": 3,
        },
    )
    assert created.status_code == 201
    cid = created.json()["id"]

    resp = client.patch(
        f"/courses/{cid}",
        headers=headers,
        json={
            "code": "TEST102",
            "name": "Kursus Uji (Revisi)",
            "prodi": "S1 Pariwisata",
            "semester": 4,
            "credits": 2,
            "description": "Diedit oleh admin",
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["code"] == "TEST102"
    assert body["name"] == "Kursus Uji (Revisi)"
    assert body["prodi"] == "S1 Pariwisata"
    assert body["semester"] == 4
    assert body["credits"] == 2


def test_jurusan_crud(client):
    """Super admin dapat mengelola jurusan dan prodi di dalamnya."""
    token = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Seed menghasilkan jurusan dengan prodi di dalamnya.
    seeded = client.get("/jurusan", headers=headers)
    assert seeded.status_code == 200
    assert seeded.json(), "seed harus menghasilkan minimal 1 jurusan"
    assert all("prodi" in j for j in seeded.json())

    # Buat jurusan baru.
    created = client.post(
        "/jurusan",
        headers=headers,
        json={"name": "Keperawatan"},
    )
    assert created.status_code == 201
    jid = created.json()["id"]
    assert created.json()["prodi"] == []

    # Tambahkan prodi ke dalam jurusan tersebut.
    prodi = client.post(
        f"/jurusan/{jid}/prodi",
        headers=headers,
        json={"name": "S1 Keperawatan"},
    )
    assert prodi.status_code == 201
    pid = prodi.json()["id"]
    assert prodi.json()["jurusan_id"] == jid

    # Nama prodi tidak boleh duplikat.
    dup = client.post(
        f"/jurusan/{jid}/prodi",
        headers=headers,
        json={"name": "S1 Keperawatan"},
    )
    assert dup.status_code == 400

    # Edit nama jurusan & prodi.
    renamed = client.patch(f"/jurusan/{jid}", headers=headers, json={"name": "Kesehatan"})
    assert renamed.status_code == 200
    assert renamed.json()["name"] == "Kesehatan"

    renamed_prodi = client.patch(
        f"/jurusan/prodi/{pid}", headers=headers, json={"name": "D3 Keperawatan"}
    )
    assert renamed_prodi.status_code == 200
    assert renamed_prodi.json()["name"] == "D3 Keperawatan"

    # Jurusan menampilkan prodi yang sudah diubah.
    listed = client.get("/jurusan", headers=headers)
    regenerated = next(j for j in listed.json() if j["name"] == "Kesehatan")
    prodi_names = [p["name"] for p in regenerated["prodi"]]
    assert prodi_names == ["D3 Keperawatan"]

    # Hapus prodi lalu jurusan.
    assert client.delete(f"/jurusan/prodi/{pid}", headers=headers).status_code == 204
    assert client.delete(f"/jurusan/{jid}", headers=headers).status_code == 204
    assert client.get("/jurusan", headers=headers).json() == seeded.json()


def test_jurusan_write_blocked_for_non_admin(client):
    """Mahasiswa tidak bisa membuat jurusan."""
    token = client.post(
        "/auth/login",
        json={"email": "mahasiswa1@vocalearn.id", "password": "siswa123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = client.post("/jurusan", headers=headers, json={"name": "Illegal"})
    assert resp.status_code == 403


def test_admin_stats_include_jurusan_monitoring(client):
    """Monitoring admin menyertakan statistik per jurusan (mahasiswa, MK,
    modul, dan interaksi yang terhubung lewat prodi)."""
    token = client.post(
        "/auth/login",
        json={"email": "admin@vocalearn.id", "password": "admin123"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    stats = client.get("/admin/stats", headers=headers)
    assert stats.status_code == 200
    body = stats.json()

    assert "jurusan_stats" in body
    assert body["jurusan_stats"], "seed harus menghasilkan statistik jurusan"

    for jurusan in body["jurusan_stats"]:
        assert jurusan["total_prodi"] >= 1
        assert jurusan["total_students"] >= 0
        assert jurusan["total_courses"] >= 0
        assert jurusan["total_modules"] >= 0
        assert jurusan["total_interactions"] >= 0
        assert jurusan["avg_score"] >= 0

    # Mahasiswa seed berada di prodi dalam jurusan, jadi tersebar di sini.
    total_students = sum(j["total_students"] for j in body["jurusan_stats"])
    assert total_students >= 5
