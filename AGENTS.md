# AGENTS.md

## Repo structure

Two independent parts sharing one repo:

- **`vocalearn-backend/`** — Python FastAPI + SQLAlchemy + SQLite. All backend code lives here.
- **`lib/`** — Flutter frontend (Android-first). Clean architecture: `core/`, `data/`, `domain/`, `features/`, `screens/`.

They are wired together only via HTTP ( Dio HTTP client in Flutter → FastAPI on port 8000).

## Backend commands

All from `vocalearn-backend/`:

```bash
python -m venv venv && venv\Scripts\activate   # Windows
pip install -r requirements.txt
cp .env.example .env                            # then fill GEMINI_API_KEY etc.
python -m app.seed                              # idempotent demo data
uvicorn app.main:app --reload --port 8000       # dev server
pytest tests -v                                 # runs against separate test_vocalearn.db
```

**Single test file:** `vocalearn-backend/tests/test_main.py`. Tests use a separate SQLite DB (`test_vocalearn.db`) with env vars overridden in `conftest.py` — no Gemini API calls in tests.

**No DB migrations.** Tables are created at startup via `Base.metadata.create_all`. If schema changes, delete `*.db` files and re-run `python -m app.seed`.

**Gemini routes return 503** if `GEMINI_API_KEY` is empty/missing. This is expected in test mode.

## Frontend commands

```bash
flutter analyze          # uses analysis_options.yaml + flutter_lints
flutter test             # if tests exist
flutter run              # needs emulator/device
```

**API base URL:** `lib/core/config/app_config.dart` — hardcoded to `192.168.10.13:8000` for Android emulator, `localhost:8000` for other platforms. Override via `--dart-define=API_BASE_URL=...`.

**Routing:** Single `GoRouter` in `lib/core/router/app_router.dart` with 3 role-based tracks: `/mahasiswa`, `/dosen`, `/admin`. Client-side RBAC redirect only — backend must also enforce via `deps.py` guards.

**State management:** Riverpod (`flutter_riverpod`). Providers in `lib/data/providers/` and `lib/providers/`.

## Conventions

- Comments and error messages are in **Bahasa Indonesia** (e.g., `detail="Autentikasi diperlukan"`).
- Python indent: 4 spaces. Dart/JS/YAML/JSON indent: 2 spaces (see `.editorconfig`).
- Backend RBAC guards: `require_super_admin`, `require_dosen_or_admin`, `require_any_authenticated` in `vocalearn-backend/app/deps.py`.
- Backend routers: one file per resource in `vocalearn-backend/app/routers/`. Services contain business logic.

## Gotchas

- `.env` is gitignored — never commit secrets.
- `AppConfig` in `lib/core/config/app_config.dart` has demo credentials (`admin@vocalearn.id` / `admin123`). These are for dev only.
- The Flutter `lib/main.dart` is still the default counter template — the real app entry is wired through `lib/core/router/app_router.dart` and `features/`.
- Backend seed data accounts: `admin@vocalearn.id`, `dosen1@vocalearn.id`, `mahasiswa1@vocalearn.id`–`mahasiswa5@vocalearn.id`. Passwords: `admin123`, `dosen123`, `siswa123`.
- No CI/CD workflows exist in this repo.
