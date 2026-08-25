import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_role.dart';
import '../../data/providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/mahasiswa/mahasiswa_shell.dart';
import '../../features/mahasiswa/chat_tutor_screen.dart';
import '../../features/mahasiswa/onboarding_screen.dart';
import '../../features/mahasiswa/profile_screen.dart';
import '../../features/mahasiswa/diagnostic_screen.dart';
import '../../features/mahasiswa/module_detail_screen.dart';
import '../../features/mahasiswa/quiz_screen.dart';
import '../../features/dosen/dosen_shell.dart';
import '../../features/dosen/upload_materi_screen.dart';
import '../../features/dosen/student_list_screen.dart';
import '../../features/dosen/student_detail_screen.dart';
import '../../features/admin/admin_home_screen.dart';

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
      // MahasiswaShell handles bottom nav with IndexedStack
      GoRoute(
        path: '/mahasiswa',
        builder: (context, state) => const MahasiswaShell(),
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
            path: 'modules/:id',
            builder: (context, state) => ModuleDetailScreen(
              moduleId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => const ChatTutorScreen(),
          ),
          GoRoute(
            path: 'quiz/:materialId',
            builder: (context, state) => QuizScreen(
              materialId: int.parse(state.pathParameters['materialId']!),
              materialTitle: state.uri.queryParameters['title'] ?? 'Kuis',
            ),
          ),
        ],
      ),

      // ---------- TRACK DOSEN ----------
      GoRoute(
        path: '/dosen',
        builder: (context, state) => const DosenShell(),
        routes: [
          GoRoute(
            path: 'upload',
            builder: (context, state) => const UploadMateriScreen(),
          ),
          GoRoute(
            path: 'students',
            builder: (context, state) => const StudentListScreen(),
          ),
          GoRoute(
            path: 'students/:id',
            builder: (context, state) => StudentDetailScreen(
              studentId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),

      // ---------- TRACK SUPER ADMIN ----------
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
    ],
  );
});
