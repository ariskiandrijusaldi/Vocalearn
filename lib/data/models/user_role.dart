/// 3 role utama VocaLearn.
/// Dipakai oleh: role-based routing (go_router), RBAC di API, dan UI switch.
///
/// PEMBAGIAN KERJA TIM (lihat TASK_DIVISION.md):
/// - mahasiswa -> dikerjakan oleh PIC Track Mahasiswa
/// - dosen     -> dikerjakan oleh PIC Track Dosen
/// - superAdmin-> dikerjakan oleh PIC Track Admin
enum UserRole { mahasiswa, dosen, superAdmin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.dosen:
        return 'Dosen';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  /// Path awal (home route) untuk masing-masing role.
  String get homePath {
    switch (this) {
      case UserRole.mahasiswa:
        return '/mahasiswa';
      case UserRole.dosen:
        return '/dosen';
      case UserRole.superAdmin:
        return '/admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'dosen':
        return UserRole.dosen;
      case 'superAdmin':
      case 'admin':
        return UserRole.superAdmin;
      case 'mahasiswa':
      default:
        return UserRole.mahasiswa;
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}