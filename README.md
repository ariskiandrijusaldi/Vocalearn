# Vocalearn

**Adaptive Language Learning** — aplikasi belajar bahasa asing adaptif.

Repo ini berisi dua bagian:

- **`vocalearn-backend/`** — Backend API FastAPI + SQLite + integrasi AI Gemini. Termasuk autentikasi JWT, RBAC, workflow review modul, dan mesin rekomendasi adaptif. Lihat [vocalearn-backend/README.md](vocalearn-backend/README.md) untuk setup, menjalankan server, dan test.
- **`lib/`** — Frontend Flutter (Super Admin UI). Di-wire melalui `lib/main.dart` dengan `AdminHomeScreen`.

## Mulai cepat (backend)

```bash
cd vocalearn-backend
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
cp .env.example .env         # lalu isi GEMINI_API_KEY dll.
python -m app.seed           # data demo
uvicorn app.main:app --reload --port 8000
pytest tests -v              # jalankan test
```
