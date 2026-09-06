# AGENTS.md

## Repo structure

Two independent parts sharing one repo:

- **`vocalearn-backend/`** — Python FastAPI + SQLAlchemy + SQLite/MySQL. All backend code lives here.
- **`lib/`** — Flutter frontend (Android-first). Structure: `core/` (config, router, theme, utils), `data/` (models, providers, repositories), `features/` (admin, auth, dosen, mahasiswa). Legacy `lib/models/materi_model.dart` and `lib/providers/materi_provider.dart` are leftovers; real code lives under `data/`.

They are wired together only via HTTP (Dio HTTP client in Flutter → FastAPI on port 8000).

## Backend commands

All from `vocalearn-backend/`:

```bash
python -m venv venv && venv\Scripts\activate   # Windows
pip install -r requirements.txt
cp .env.example .env                            # then fill GEMINI_API_KEY etc.
python -m app.seed                              # idempotent demo data
uvicorn app.main:app --host 0.0.0.0 --reload --port 8000   # dev server (or: python main.py)
pytest tests -v                                 # runs against separate test_vocalearn.db
pytest tests/test_main.py::test_login_admin -v  # single test
```

**Tests:** All backend tests are in the single file `vocalearn-backend/tests/test_main.py` — **14 integration tests** (login, dosen/jurusan scoping, module publishes directly, admin leaderboard + mahasiswa class-scoped leaderboard, jurusan/prodi CRUD, `/admin/stats` jurusan monitoring). `conftest.py` deletes & re-seeds a separate SQLite DB (`test_vocalearn.db`) per session and overrides env vars — no Gemini API calls run in tests.

**No DB migrations.** Tables are created at startup via `Base.metadata.create_all`. If schema changes, delete `*.db` files and re-run `python -m app.seed`. On the dev **MySQL** DB, `create_all` will NOT add new columns to existing tables — run the matching `ALTER TABLE` manually (e.g. `ALTER TABLE users ADD COLUMN jurusan_id INT NULL, ADD INDEX ix_users_jurusan_id (jurusan_id);`) before re-seeding.

**Dosen are scoped to a jurusan.** `users.jurusan_id` (nullable FK → `jurusans`) marks the jurusan a dosen teaches; seed sets all dosen to Teknologi Informasi. Super admin sets it per-dosen in the admin **Dosen** tab (dropdown → `PATCH /admin/users/{id}` with `jurusan_id`; the create form accepts `jurusan_id` too). `GET /courses` returns only courses whose `prodi` belongs to that jurusan for dosen (admin/mahasiswa see all). `GET /kelas` for dosen returns only the classes they teach (`kelas.dosen_id == user.id`); admin sees all. `GET /auth/me` includes `jurusan_name`. The dosen upload form (`upload_materi_screen.dart`) shows the jurusan and an empty-state when no courses match.

**Jurusan/prodi linkage is by string name, not FK.** `courses.prodi` and `users.prodi` are plain `String` columns equal to `prodi.name`; `prodi.jurusan_id` → `jurusans` maps them to a jurusan (see `course.py`'s dosen filter). Renaming a prodi via the admin Jurusan tab does NOT rewrite existing course/user rows — the dosen's scoped course list silently changes. `GET /jurusan` (read: any authenticated) returns jurusan with nested prodi; writes (`/jurusan`, `/jurusan/{id}/prodi`) are super-admin only.

**Leaderboard scoping** (`app/routers/leaderboard.py` + `dosen.py`): `GET /leaderboard` for a mahasiswa returns their ENTIRE own class (those with zero progress get `rank: null`), while admin/dosen see only students with activity. `GET /dosen/leaderboard` groups by class, ranked by average score desc (inactive students at bottom, `rank: null`).

**Module file uploads** are stored under `vocalearn-backend/app/uploads/modules/` (auto-created at startup) and served statically at `/uploads/modules`.

**Gemini routes return 503** if `GEMINI_API_KEY` is empty/missing. This is expected in test mode. The recommendation engine gracefully degrades (returns `None` for AI suggestion). If the default model (`models/gemini-3.6-flash`) is overloaded/503s or returns 404 "no longer available", set `GEMINI_MODEL` in `.env` (e.g. `models/gemini-3.6-flash-lite`) and restart the server. Gemini deprecates old model names for new API keys periodically — a 404 NOT_FOUND naming a replacement model means exactly this.

**All Gemini features live under `/ai/*`** in `app/routers/gemini.py`: simplify-material (+ PDF download), generate-quiz, explain-wrong-answer, chat-tutor (rate-limited 10 msgs/min per student, **in-memory** — resets on server restart), quiz submit/result/attempts, diagnostic (one-time per student). `_call_gemini` retries 4× with backoff; free-tier quota (429) short-circuits.

**Database:** `.env.example` defaults to MySQL via Laragon (`mysql+pymysql://root:@localhost:3306/vocalearn`). Config falls back to SQLite if `DATABASE_URL` starts with `sqlite`. Tests always use SQLite.

**AI engine** (`app/ai/`): 4 modules — `risk.py` (rule-based), `competency.py` (weighted + BKT), `scheduler.py` (next-module recommender), `advice.py` (Gemini, with 30-min cache + fallback templates). Only `advice.py` requires Gemini.

**Settings** (`app/config.py`): Plain Python class with `os.getenv()`, NOT Pydantic BaseSettings. `load_dotenv()` runs at import time — env vars must be set before any `app.*` import.

## Frontend commands

```bash
flutter analyze          # uses analysis_options.yaml + flutter_lints
flutter test             # 4 widget tests in 3 files; admin tests inject fake services via Riverpod overrides (no backend needed)
flutter run              # needs emulator/device
```

**API base URL:** `lib/core/config/app_config.dart` — Android default is a **hardcoded machine-specific LAN IP** (`_androidBaseUrl`, currently `http://192.168.1.12:8000` — update it to your machine's IP, or pass `--dart-define=API_BASE_URL=...`). Other platforms use `localhost:8000`. Backend must listen on `0.0.0.0`, which `python main.py` does.

**Routing:** Single `GoRouter` in `lib/core/router/app_router.dart` with 3 role-based tracks: `/mahasiswa` (onboarding, profile, diagnostic, modules/:id, chat, quiz/:materialId), `/dosen` (`upload`, `students`, `students/:id`), `/admin` (dashboard only). Redirect logic bounces any logged-in user off routes outside their role prefix. Client-side RBAC only — backend must also enforce via `deps.py` guards. The redirect is driven by a `refreshListenable` (`_AuthRouterRefresh`) that **only notifies on `isLoggedIn` changes** — not on loading/error — so a failed login (wrong password) does not remount the route tree. Don't "simplify" it by having the provider `ref.watch(authProvider)` directly, or you'll break that.

**HTTP layer:** `ApiClient` singleton (`lib/core/config/api_client.dart`) — one Dio instance for the whole app; its interceptor injects the JWT read from `flutter_secure_storage`. Per-role endpoint wrappers live in `lib/data/repositories/` (`ai_service.dart`, `admin_service.dart`, `dosen_service.dart`) — put new API calls there, not in widgets.

**State management:** Riverpod (`flutter_riverpod`). Providers in `lib/data/providers/` and `lib/providers/`.

## Role Architecture (Flutter)

Single source of truth: `lib/data/models/user_role.dart`

```dart
enum UserRole {
  mahasiswa(label: 'Mahasiswa', homePath: '/mahasiswa'),
  dosen(label: 'Dosen', homePath: '/dosen'),
  superAdmin(label: 'Super Admin', homePath: '/admin');
}

UserRole parseUserRole(String value);  // handles "mahasiswa", "dosen", "superAdmin", "super_admin", "admin"; unknown values silently default to mahasiswa
```

Data flow: Backend JSON `{"role": "mahasiswa"}` → `parseUserRole()` → `UserRole` enum → `ApiUser.role` → GoRouter redirect.

## Conventions

- Comments and error messages are in **Bahasa Indonesia** (e.g., `detail="Autentikasi diperlukan"`).
- Python indent: 4 spaces. Dart/JS/YAML/JSON indent: 2 spaces (see `.editorconfig`).
- Backend RBAC guards in `vocalearn-backend/app/deps.py`: `require_super_admin`, `require_dosen_or_admin` (includes super_admin), `require_any_authenticated`, and `require_roles(...)` for custom combinations.
- Backend routers: one file per resource in `vocalearn-backend/app/routers/`. Services contain business logic.

## Gotchas

- `.env` is gitignored — never commit secrets.
- `AppConfig` in `lib/core/config/app_config.dart` has demo credentials (`admin@vocalearn.id` / `admin123`). These are for dev only.
- Backend seed data accounts: `admin@vocalearn.id`, `dosen1@vocalearn.id`, `dosen2@vocalearn.id`, `mahasiswa1@vocalearn.id`–`mahasiswa5@vocalearn.id`. Passwords: `admin123`, `dosen123`, `siswa123`.
- No CI/CD workflows exist in this repo.
- Backend RBAC is enforced by FastAPI dependencies (`deps.py`), not middleware — guard functions are injected per-route via `Depends(...)`.
- `conftest.py` sets env vars **before** importing `app.*` — this ordering is critical so `config.py` reads test values.
- `vocalearn-backend/list_models.py` contains a hardcoded API key and uses the legacy `google.generativeai` SDK. It is gitignored — never commit it. The main app uses the newer `google-genai` package (see `requirements.txt`).
- Dosen screens use **mixed navigation**: GoRouter routes exist for `/dosen/upload` and `/dosen/students`, but `dosen_dashboard_screen.dart` and `student_list_screen.dart` still open detail screens (module edit via `EditModuleScreen`, student detail) via `Navigator.push`, bypassing RBAC redirect logic. Prefer `context.go()` for new navigation.
- Root `README.md` is stale about the frontend: it describes `lib/` as a "Super Admin UI" wired to `AdminHomeScreen`. Reality: 3 role tracks (mahasiswa/dosen/admin) per the router. Trust this file over README for frontend structure.
