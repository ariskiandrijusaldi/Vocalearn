import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_role.dart';
import '../../data/providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/mahasiswa/mahasiswa_home_screen.dart';
import '../../features/mahasiswa/onboarding_screen.dart';
import '../../features/mahasiswa/profile_screen.dart';
import '../../features/mahasiswa/diagnostic_screen.dart';
import '../../features/mahasiswa/module_list_screen.dart';
import '../../features/mahasiswa/module_detail_screen.dart';
import '../../features/mahasiswa/progress_screen.dart';
import '../../features/dosen/dosen_dashboard_screen.dart';
import '../../features/admin/admin_home_screen.dart';

/// Router tunggal untuk 3 role. Redirect logic memastikan:
///  - Belum login -> selalu diarahkan ke /login
///  - Sudah login -> tidak boleh membuka route milik role lain
///    (mis. mahasiswa tidak bisa buka /admin, dst — RBAC sisi client;
///     tetap WAJIB diverifikasi ulang di backend, lihat to-do §3)
///
/// PIC integrasi: siapa pun yang menambah screen baru di masing-masing
/// track tinggal menambahkan GoRoute baru di dalam branch role terkait,
/// tanpa menyentuh kode track lain -> aman dikerjakan paralel oleh 3 orang.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final goingToLogin = state.matchedLocation == '/login';

      if (!loggedIn) return goingToLogin ? null : '/login';

      final role = authState.user!.role;
      if (goingToLogin) return role.homePath;

      final path = state.matchedLocation;
      final isOnOwnRoute = switch (role) {
        UserRole.mahasiswa => path.startsWith('/mahasiswa'),
        UserRole.dosen => path.startsWith('/dosen'),
        UserRole.superAdmin => path.startsWith('/admin'),
      };
      if (!isOnOwnRoute) return role.homePath;

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // ---------- TRACK MAHASISWA ----------
      GoRoute(
        path: '/mahasiswa',
        builder: (context, state) => const MahasiswaHomeScreen(),
        routes: [
          GoRoute(
            path: 'onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'diagnostic',
            builder: (context, state) => const DiagnosticScreen(),
          ),
          GoRoute(
            path: 'modules',
            builder: (context, state) => const ModuleListScreen(),
          ),
          GoRoute(
            path: 'modules/:id',
            builder: (context, state) => ModuleDetailScreen(
              moduleId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'progress',
            builder: (context, state) => const ProgressScreen(),
          ),
        ],
      ),

      // ---------- TRACK DOSEN ----------
      GoRoute(
        path: '/dosen',
        builder: (context, state) => const DosenDashboardScreen(),
        routes: [
          // TODO (PIC Dosen): tambah sub-route di sini, contoh:
          // GoRoute(path: 'students/:id', builder: (c, s) => StudentDetailScreen(id: s.pathParameters['id']!)),
        ],
      ),

      // ---------- TRACK SUPER ADMIN ----------
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          // TODO (PIC Admin): tambah sub-route di sini, contoh:
          // GoRoute(path: 'users', builder: (c, s) => const UserManagementScreen()),
          // GoRoute(path: 'courses', builder: (c, s) => const MataKuliahManagementScreen()),
        ],
      ),
    ],
  );
});