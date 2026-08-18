enum UserRole {
  student,
  lecturer,
  admin;

  String get label => switch (this) {
        UserRole.student => 'Mahasiswa',
        UserRole.lecturer => 'Dosen',
        UserRole.admin => 'Admin',
      };

  String get apiValue => switch (this) {
        UserRole.student => 'mahasiswa',
        UserRole.lecturer => 'dosen',
        UserRole.admin => 'super_admin',
      };

  static UserRole fromApi(String value) => switch (value) {
        'mahasiswa' => UserRole.student,
        'dosen' => UserRole.lecturer,
        'super_admin' => UserRole.admin,
        _ => UserRole.student,
      };
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.nim,
    this.nip,
    this.prodi,
    this.isActive = true,
    this.createdAt,
  });

  final int id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? nim;
  final String? nip;
  final String? prodi;
  final bool isActive;
  final DateTime? createdAt;

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? nim,
    String? nip,
    String? prodi,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      nim: nim ?? this.nim,
      nip: nip ?? this.nip,
      prodi: prodi ?? this.prodi,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
