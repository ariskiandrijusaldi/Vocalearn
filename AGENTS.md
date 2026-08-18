# VocaLearn — Agent Guide

Flutter mobile app (vocational-student adaptive learning). SDK >=3.3.0 <4.0.0.

## Quick commands

```bash
flutter pub get          # install deps
flutter run              # run app
flutter test             # run tests (smoke test only)
flutter analyze          # lint via flutter_lints
flutter build apk        # Android release build
```

## Project structure

```
lib/
  main.dart                 # App entry — ProviderScope wraps the entire widget tree
  core/
    router/app_router.dart  # GoRouter with role-based RBAC redirect logic
    theme/app_theme.dart    # Shared Material 3 theme (seed: #2F6FED)
  data/
    models/
      user_role.dart        # UserRole enum: mahasiswa | dosen | superAdmin + AppUser
      competency.dart       # Competency, PracticeModule, CompetencyStatus
    providers/
      auth_provider.dart    # AuthController (mock login — role inferred from email)
      competency_provider.dart  # CompetencyController + score-to-status thresholds
      module_provider.dart  # ModuleController + simple recommendation logic
      assistant_provider.dart
      student_profile_provider.dart
  features/
    auth/login_screen.dart
    mahasiswa/              # 7 screens — home, onboarding, profile, diagnostic, modules, progress
    dosen/                  # 1 screen — dosen_dashboard_screen (stub, expand sub-routes)
    admin/                  # 1 screen — admin_home_screen (stub, expand sub-routes)
```

## Architecture

- **State management:** Riverpod (`flutter_riverpod`). All providers are in `lib/data/providers/`.
- **Routing:** GoRouter. Single router with role-based redirect — routes are namespaced by role (`/mahasiswa`, `/dosen`, `/admin`). Adding a screen = adding a `GoRoute` in the correct role branch of `app_router.dart`.
- **Auth:** Currently mocked. `AuthController.login` infers role from email string (`dosen` → dosen, `admin` → superAdmin, else mahasiswa). No backend call. **Do not assume auth is real.**
- **No backend yet.** All data is local/mock. The `dio` dependency is declared but unused.

## Key conventions

- **All screens are role-isolated.** Do not cross-import screens between `features/mahasiswa`, `features/dosen`, `features/admin`. Routing enforces RBAC client-side; backend verification is still TODO.
- **Theme:** Pull colors/fonts from `Theme.of(context)` — never hardcode colors. The shared theme is defined in `app_theme.dart`.
- **Language:** Code comments, string literals, and variable names use **Bahasa Indonesia** (e.g. `belumMulai`, `perluIntervensi`, `terkunci`). Follow this convention.
- **Competency score thresholds:** `< 0.4` = perluIntervensi, `<= 0.7` = dalamProses, `> 0.7` = dikuasai. These are defined in `competency_provider.dart:24` and documented in the Mini-PRD.
- **Module recommendation logic:** Within a competency, first incomplete module is "direkomendasikan"; later ones are "terkunci". Competencies sorted lowest-score-first. Local MVP logic in `module_provider.dart` — will be replaced by backend AI Engine.

## Testing

- Single smoke test: `test/widget_test.dart` — verifies app launches and shows Login screen.
- Run with: `flutter test`
- Tests wrap `VocaLearnApp` in `ProviderScope` (required for Riverpod).

## Gotchas

- `flutter_secure_storage` is a dependency but not yet wired in — no token persistence exists.
- `lottie`, `video_player`, `chewie`, `fl_chart` are dependencies; not all are used in screens yet.
- The dosen and admin feature directories each have only a stub screen; sub-routes are empty TODOs in `app_router.dart`.
- `app_router.dart` is the single source of truth for navigation — never add routes outside it.
