# Vocalearn Backend

Backend API (FastAPI + SQLAlchemy + SQLite) untuk **VocaLearn — Adaptive Language Learning**. Menyediakan autentikasi (JWT), manajemen pengguna/mata kuliah/modul, workflow review modul, pencatatan interaksi latihan, mesin rekomendasi adaptif berbasis aturan, dan fitur AI Gemini (penyederhanaan materi, pembuatan kuis, tutor chat).

## Struktur

```
app/
├── main.py          # Instance FastAPI + registrasi router
├── config.py        # Pengaturan dari .env (pydantic-style Settings)
├── database.py      # Engine SQLAlchemy, SessionLocal, Base, init_db()
├── deps.py          # Dependensi RBAC (get_current_user, require_*)
├── security.py      # Hashing password + JWT
├── seed.py          # Isi data demo (idempotent)
├── models/          # Model SQLAlchemy per domain
├── schemas/         # Skema Pydantic per domain
├── services/        # Logika bisnis (dipakai router)
├── ai/              # Mesin rekomendasi rule-based + integrasi Gemini
└── routers/         # Endpoint HTTP per resource
tests/               # Test pytest (smoke test endpoint utama)
```

## Setup

1. Buat virtual environment dan aktifkan:

   ```bash
   python -m venv venv
   # Windows: venv\Scripts\activate   |   Linux/macOS: source venv/bin/activate
   ```

2. Install dependensi:

   ```bash
   pip install -r requirements.txt
   ```

3. Salin `.env.example` menjadi `.env`:

   ```bash
   cp .env.example .env
   ```

   Isi nilai sesuai kebutuhan. Variabel yang tersedia:

   | Variabel | Keterangan |
   |---|---|
   | `GEMINI_API_KEY` | Kunci API Google Gemini. Wajib untuk route AI; tanpa ini route Gemini mengembalikan 503. |
   | `JWT_SECRET` | Secret penandatangan token. Gunakan string acak panjang (≥32 karakter) di produksi. |
   | `ACCESS_TOKEN_EXPIRE_MINUTES` | Masa berlaku token (menit), default `1440`. |
   | `DATABASE_URL` | Koneksi database, default SQLite `sqlite:///./vocalearn.db`. |

   > Jangan commit `.env` — sudah diabaikan oleh `.gitignore`.

## Menjalankan server

```bash
uvicorn app.main:app --reload --port 8000
```

Atau lewat entrypoint:

```bash
python main.py
```

Dokumentasi interaktif (Swagger): http://localhost:8000/docs

### Data demo

```bash
python -m app.seed
```

Akun bawaan (password: `admin123` untuk admin, `dosen123` untuk dosen, `siswa123` untuk mahasiswa):

| Role | Email |
|---|---|
| Super Admin | `admin@vocalearn.id` |
| Dosen | `dosen1@vocalearn.id` |
| Mahasiswa | `mahasiswa1@vocalearn.id` s.d. `mahasiswa5@vocalearn.id` |

## Menjalankan test

```bash
pytest tests -v
```

Test memakai database SQLite terpisah (`test_vocalearn.db`) dan tanpa panggilan Gemini sungguhan (lihat `tests/conftest.py`).

## Catatan

- Tidak ada migrasi database: tabel dibuat otomatis saat startup (`Base.metadata.create_all`). Jika skema berubah, hapus file `*.db` lalu jalankan ulang `python -m app.seed`.
- Konvensi: komentar dan pesan `detail` error menggunakan Bahasa Indonesia.
