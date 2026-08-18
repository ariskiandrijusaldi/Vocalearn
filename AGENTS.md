# AGENTS.md

Vocalearn: a Flutter frontend + a Python FastAPI backend. The product logic lives in `vocalearn-backend/`; the Flutter app is a working Super Admin UI backed partly by in-memory dummy data and partly by real API calls.

## Backend (Python / FastAPI)

- Entrypoints: `vocalearn-backend/main.py` -> `app/main.py` (FastAPI app). `app/` is modular: `models/` and `schemas/` (SQLAlchemy/Pydantic, per-domain, re-exported from `app/models/__init__.py` / `app/schemas/__init__.py` so `from app.models import X` still works), `services/` (business logic — routers must stay thin), `routers/` (auth, admin, course, module, interaction, recommendation, gemini), `ai/`.
- Use the repo's venv directly (Windows): `vocalearn-backend\.\venv\Scripts\python.exe`.
- Run the server: `python main.py` (uvicorn on `0.0.0.0:8000`, reload). API docs at `http://localhost:8000/docs`.
- Tests: `vocalearn-backend\.\venv\Scripts\python.exe -m pytest tests -v`. They use a separate `test_vocalearn.db` and disable Gemini (see `tests/conftest.py`); no network needed.
- Seed demo data (idempotent): `python -m app.seed`. Accounts: `admin@vocalearn.id / admin123`, `dosen1@vocalearn.id / dosen123`, `mahasiswa1@vocalearn.id / siswa123` (up to `mahasiswa5`).
- DB is SQLite (`vocalearn-backend/vocalearn.db`); tables auto-create at startup via `Base.metadata.create_all` (`app/database.py`) — NO migrations. Schema changes won't apply to an existing DB; delete the `.db` and re-seed.
- Config from `vocalearn-backend/.env` (copy `.env.example`). Without `GEMINI_API_KEY` the Gemini routes (`/test-ai`, `/simplify-material`, `/generate-quiz`, `/explain-wrong-answer`, `/chat-tutor`) return 503.
- Roles `super_admin` / `dosen` / `mahasiswa`; RBAC via `require_super_admin`, `require_dosen_or_admin`, `require_any_authenticated` in `app/deps.py`. Most routes need a Bearer token from `POST /auth/login`. Super-admin-only: `/admin/users` (CRUD, soft delete via `is_active`), `/admin/stats`, `/admin/integrations`.
- `app/ai/` is rule-based, not ML: `risk.py` (threshold risk), `competency.py`/`scheduler.py` (mastery + next module), `advice.py` (Gemini `ai_suggestion`, falls back to a template on failure). `app/services/recommendation_service.py` composes them; the router only enforces RBAC (mahasiswa can only fetch their own).
- Module workflow is `draft -> review -> published` (`submit`/`approve`/`reject`); published modules can't be edited.
- Conventions: comments and user-facing error `detail` messages are written in Indonesian — keep that style for new code.

## Flutter app

- SDK `^3.11.0`. Verify with `flutter analyze` and `flutter test`.
- **`pubspec.yaml` is incomplete**: source code imports `http` and `fl_chart` but neither is declared in `pubspec.yaml`. Add them before building.
- **`lib/main.dart` is the default Flutter counter demo**, not the admin UI. `flutter run` shows a counter, not the admin dashboard. `test/widget_test.dart` works around this by directly constructing `AdminHomeScreen` with in-memory repos (does not go through `main.dart`).
- Clean architecture: `lib/domain/` (entities + repository interfaces), `lib/data/` (datasources + implementations), `lib/features/admin/presentation/` (screens + widgets). The real main screen is `lib/features/admin/presentation/screens/admin_home_screen.dart`.
- Two repository implementations are active:
  - `AdminRepositoryImpl` (`lib/data/repositories/admin_repository_impl.dart`) — in-memory CRUD over `lib/data/datasources/local/dummy_data.dart` (mirrors seed data). No backend needed.
  - `RecommendationApiRepository` (`lib/data/repositories/recommendation_api_repository.dart`) — real HTTP to the backend; auto-logs-in as admin, calls `/admin/users` and `/recommendation/{id}` with a 5-min cache. A down backend breaks only the "Rekomendasi" tab.
  - Two others exist but are NOT wired in: `AdminApiRepository` (full HTTP CRUD) and `RecommendationRepositoryImpl` (in-memory).
- Admin UI has 4 tabs (Mahasiswa, Dosen, Modul, Rekomendasi). Mahasiswa/Dosen/Modul run off the in-memory `AdminRepositoryImpl`; Rekomendasi off the live API.
- Base URL from `lib/core/config/app_config.dart`: hardcoded `http://192.168.10.13:8000` on Android, `http://localhost:8000` otherwise; override with `--dart-define=API_BASE_URL=http://<host>:8000`. Admin auto-login creds (`admin@vocalearn.id / admin123`) are hardcoded there too.
- `lib/SuperAdmin/` and `lib/mahasiswa/` are dead login/logout stubs (not referenced): each file is a single unused `package:flutter/material.dart` import, which is what produces the 4 `unused_import` warnings in `flutter analyze`.

## Security gotchas

- `vocalearn-backend/.gitignore` (added) ignores `.env`, `list_models.py`, `*.db`, `venv/`, `*.log`, `__pycache__/`, `.pytest_cache/`. These files exist on disk and are untracked — never force-add or commit them. `list_models.py` still has a real API key hardcoded.
- `.gitignore` is the Flutter default at the repo root and ignores none of the backend files — the backend rules live in `vocalearn-backend/.gitignore`; rely on that.
- `list_models.py` imports `google.generativeai`, which conflicts with the `google-genai` package in `requirements.txt` (the app uses `from google import genai`). Don't rely on that script.
- The Android manifest lacks `INTERNET` permission and cleartext-HTTP config — if HTTP calls fail on a physical Android device or release build, that's where to look.
