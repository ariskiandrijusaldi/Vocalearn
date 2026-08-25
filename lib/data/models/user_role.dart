/// 3 role utama VocaLearn.
enum UserRole {
  mahasiswa(label: 'Mahasiswa', homePath: '/mahasiswa'),
  dosen(label: 'Dosen', homePath: '/dosen'),
  superAdmin(label: 'Super Admin', homePath: '/admin');

  final String label;
  final String homePath;

  const UserRole({required this.label, required this.homePath});
}

UserRole parseUserRole(String value) {
  switch (value) {
    case 'dosen':
      return UserRole.dosen;
    case 'superAdmin':
    case 'super_admin':
    case 'admin':
      return UserRole.superAdmin;
    case 'mahasiswa':
    default:
      return UserRole.mahasiswa;
  }
}
