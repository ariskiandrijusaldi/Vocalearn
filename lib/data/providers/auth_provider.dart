import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';

/// State auth sederhana. Untuk hackathon, login di-mock (tidak call backend).
/// TODO (Integrasi lanjut / PIC Backend): ganti [AuthController.login] agar
/// memanggil endpoint auth asli (Firebase Auth / REST API) dan
/// mengembalikan role dari response server.
class AuthState {
  final AppUser? user;
  final bool isLoading;

  const AuthState({this.user, this.isLoading = false});

  bool get isLoggedIn => user != null;

  AuthState copyWith({AppUser? user, bool? isLoading}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  /// Login mock: role ditentukan dari akun dummy.
  /// Akun dummy untuk demo (lihat TASK_DIVISION.md & to-do list §10):
  ///   mahasiswa@vocalearn.dev / password  -> role mahasiswa
  ///   dosen@vocalearn.dev     / password  -> role dosen
  ///   admin@vocalearn.dev     / password  -> role superAdmin (TIDAK self-register)
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400)); // simulasi network

    UserRole role;
    if (email.contains('dosen')) {
      role = UserRole.dosen;
    } else if (email.contains('admin')) {
      role = UserRole.superAdmin;
    } else {
      role = UserRole.mahasiswa;
    }

    state = AuthState(
      user: AppUser(
        id: 'demo-${role.name}',
        name: 'Akun Demo ${role.label}',
        email: email,
        role: role,
      ),
      isLoading: false,
    );
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(),
);