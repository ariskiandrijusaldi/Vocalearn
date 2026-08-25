import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/admin_service.dart';
import '../auth/change_password_dialog.dart';
import '../dosen/student_detail_screen.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedTab = 0;

  static const _labels = [
    'Mahasiswa',
    'Dosen',
    'Mata Kuliah',
    'Monitoring',
    'Kelas',
  ];
  static const _icons = [
    Icons.school_outlined,
    Icons.co_present_outlined,
    Icons.collections_bookmark_outlined,
    Icons.query_stats_outlined,
    Icons.class_outlined,
  ];
  static const _selectedIcons = [
    Icons.school,
    Icons.co_present,
    Icons.collections_bookmark,
    Icons.query_stats,
    Icons.class_,
  ];

  void _showProfileMenu() {
    final user = ref.read(authProvider).user;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.sage,
                child: Text(
                  (user?.name ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.name ?? 'Admin',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.body,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.dark),
                title: const Text(
                  'Ganti Password',
                  style: TextStyle(color: AppColors.dark),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showChangePasswordDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.red),
                title: const Text(
                  'Keluar',
                  style: TextStyle(color: AppColors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE8DF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Halo, ${user?.name ?? 'Admin'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showProfileMenu,
                    icon: const Icon(Icons.account_circle_outlined,
                        color: AppColors.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: switch (_selectedTab) {
                0 => const _MahasiswaTab(),
                1 => const _DosenTab(),
                2 => const _CoursesTab(),
                3 => const _MonitoringTab(),
                4 => const _KelasTab(),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 77,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: Offset(0, -2),
              blurRadius: 12,
              color: Color(0x0F000000),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final active = _selectedTab == i;
            return GestureDetector(
              onTap: () {
                if (_selectedTab != i) {
                  setState(() => _selectedTab = i);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? _selectedIcons[i] : _icons[i],
                    size: 22,
                    color: active ? AppColors.greenDark : AppColors.muted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.greenDark : AppColors.muted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ==================== SHARED ====================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
      ),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Tambah',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final Future<void> Function(dynamic) onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  const _UserCard({required this.user, required this.onDelete, this.onEdit, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: Colors.black.withAlpha(15),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.sage,
              child: Text(
                ((user['full_name'] as String?) ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['full_name'] ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.body),
                  ),
                  Text(
                    user['nim'] ?? user['nip'] ?? '-',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.chevron_right, size: 22, color: AppColors.muted),
              ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.green),
                onPressed: onEdit,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
              onPressed: () => onDelete(user),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MAHASISWA TAB ====================

class _MahasiswaTab extends ConsumerStatefulWidget {
  const _MahasiswaTab();
  @override
  ConsumerState<_MahasiswaTab> createState() => _MahasiswaTabState();
}

class _MahasiswaTabState extends ConsumerState<_MahasiswaTab> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await ref.read(adminServiceProvider).getUsers();
      _users = all.where((u) => u['role'] == 'mahasiswa').toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _MahasiswaFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(adminServiceProvider).createUser(
            email: result['email']!,
            password: result['password']!,
            fullName: result['fullName']!,
            role: 'mahasiswa',
            nim: result['nim']?.isEmpty == true ? null : result['nim'],
            prodi: result['prodi']?.isEmpty == true ? null : result['prodi'],
          );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _showEditDialog(dynamic u) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _MahasiswaFormDialog(user: u),
    );
    if (result == null) return;
    try {
      await ref.read(adminServiceProvider).updateUser(u['id'], {
        'full_name': result['fullName'],
        'nim': result['nim']?.isEmpty == true ? null : result['nim'],
        'prodi': result['prodi']?.isEmpty == true ? null : result['prodi'],
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _deleteUser(dynamic u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus ${u['full_name']}?',
          style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Akun dan semua data terkait akan dihapus secara permanen.',
          style: TextStyle(color: AppColors.body),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.muted))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminServiceProvider).deleteUser(u['id']);
      setState(() {
        _users.removeWhere((item) => item['id'] == u['id']);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.body)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionHeader(title: 'Mahasiswa (${_users.length})', onAdd: _showAddDialog),
          const SizedBox(height: 12),
          if (_users.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Belum ada data mahasiswa.', style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ..._users.map((u) => _UserCard(
                user: u,
                onDelete: _deleteUser,
                onEdit: () => _showEditDialog(u),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(
                        studentId: u['id'] as int,
                      ),
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

class _MahasiswaFormDialog extends StatefulWidget {
  final dynamic user;
  const _MahasiswaFormDialog({this.user});

  @override
  State<_MahasiswaFormDialog> createState() => _MahasiswaFormDialogState();
}

class _MahasiswaFormDialogState extends State<_MahasiswaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _fullName;
  late final TextEditingController _nim;
  late final TextEditingController _prodi;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.user?['email'] ?? '');
    _password = TextEditingController();
    _fullName = TextEditingController(text: widget.user?['full_name'] ?? '');
    _nim = TextEditingController(text: widget.user?['nim'] ?? '');
    _prodi = TextEditingController(text: widget.user?['prodi'] ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _nim.dispose();
    _prodi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa',
        style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildField(_fullName, 'Nama Lengkap'),
            const SizedBox(height: 10),
            _buildField(_email, 'Email', enabled: !_isEdit),
            if (!_isEdit) ...[
              const SizedBox(height: 10),
              _buildField(_password, 'Password', obscure: true),
            ],
            const SizedBox(height: 10),
            _buildField(_nim, 'NIM'),
            const SizedBox(height: 10),
            _buildField(_prodi, 'Program Studi'),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.muted))),
        GestureDetector(
          onTap: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'email': _email.text,
                'password': _password.text,
                'fullName': _fullName.text,
                'nim': _nim.text,
                'prodi': _prodi.text,
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {bool obscure = false, bool enabled = true}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.cream2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
      validator: (v) {
        if (label == 'Password') return (v?.length ?? 0) < 6 ? 'Minimal 6 karakter' : null;
        if (label == 'Nama Lengkap' || label == 'Email') return (v?.isEmpty ?? true) ? 'Wajib diisi' : null;
        return null;
      },
    );
  }
}

// ==================== DOSEN TAB ====================

class _DosenTab extends ConsumerStatefulWidget {
  const _DosenTab();
  @override
  ConsumerState<_DosenTab> createState() => _DosenTabState();
}

class _DosenTabState extends ConsumerState<_DosenTab> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await ref.read(adminServiceProvider).getUsers();
      _users = all.where((u) => u['role'] == 'dosen').toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _DosenFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(adminServiceProvider).createUser(
            email: result['email']!,
            password: result['password']!,
            fullName: result['fullName']!,
            role: 'dosen',
            nip: result['nip']?.isEmpty == true ? null : result['nip'],
          );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _showEditDialog(dynamic u) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _DosenFormDialog(user: u),
    );
    if (result == null) return;
    try {
      await ref.read(adminServiceProvider).updateUser(u['id'], {
        'full_name': result['fullName'],
        'nip': result['nip']?.isEmpty == true ? null : result['nip'],
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _deleteUser(dynamic u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus ${u['full_name']}?',
          style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Akun dan semua data terkait akan dihapus secara permanen.',
          style: TextStyle(color: AppColors.body),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.muted))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminServiceProvider).deleteUser(u['id']);
      setState(() {
        _users.removeWhere((item) => item['id'] == u['id']);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.body)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _SectionHeader(title: 'Dosen (${_users.length})', onAdd: _showAddDialog),
          const SizedBox(height: 12),
          if (_users.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Belum ada data dosen.', style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ..._users.map((u) => _UserCard(
                user: u,
                onDelete: _deleteUser,
                onEdit: () => _showEditDialog(u),
              )),
        ],
      ),
    );
  }
}

class _DosenFormDialog extends StatefulWidget {
  final dynamic user;
  const _DosenFormDialog({this.user});

  @override
  State<_DosenFormDialog> createState() => _DosenFormDialogState();
}

class _DosenFormDialogState extends State<_DosenFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _fullName;
  late final TextEditingController _nip;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.user?['email'] ?? '');
    _password = TextEditingController();
    _fullName = TextEditingController(text: widget.user?['full_name'] ?? '');
    _nip = TextEditingController(text: widget.user?['nip'] ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _nip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isEdit ? 'Edit Dosen' : 'Tambah Dosen',
        style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildField(_fullName, 'Nama Lengkap'),
            const SizedBox(height: 10),
            _buildField(_email, 'Email', enabled: !_isEdit),
            if (!_isEdit) ...[
              const SizedBox(height: 10),
              _buildField(_password, 'Password', obscure: true),
            ],
            const SizedBox(height: 10),
            _buildField(_nip, 'NIP'),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.muted))),
        GestureDetector(
          onTap: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'email': _email.text,
                'password': _password.text,
                'fullName': _fullName.text,
                'nip': _nip.text,
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {bool obscure = false, bool enabled = true}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.cream2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
      validator: (v) {
        if (label == 'Password') return (v?.length ?? 0) < 6 ? 'Minimal 6 karakter' : null;
        if (label == 'Nama Lengkap' || label == 'Email') return (v?.isEmpty ?? true) ? 'Wajib diisi' : null;
        return null;
      },
    );
  }
}

// ==================== MATA KULIAH TAB ====================

class _CoursesTab extends ConsumerStatefulWidget {
  const _CoursesTab();
  @override
  ConsumerState<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<_CoursesTab> {
  List<dynamic> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _courses = await ref.read(adminServiceProvider).getCourses();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.response?.data is Map) {
      return e.response?.data['detail']?.toString() ?? 'Terjadi kesalahan';
    }
    return e.toString();
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _CourseFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(adminServiceProvider).createCourse(
            code: result['code']!,
            name: result['name']!,
            semester: int.tryParse(result['semester'] ?? '') ?? 1,
            credits: int.tryParse(result['credits'] ?? '') ?? 3,
            description: result['description'],
          );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: ${_errorMessage(e)}')));
      }
    }
  }

  Future<void> _deleteCourse(dynamic c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus ${c['name']}?',
          style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Mata kuliah akan dihapus permanen.',
          style: TextStyle(color: AppColors.body),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.muted))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminServiceProvider).deleteCourse(c['id']);
      setState(() {
        _courses.removeWhere((item) => item['id'] == c['id']);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: ${_errorMessage(e)}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.body)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(children: [
            Expanded(
              child: Text(
                'Mata Kuliah (${_courses.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
            GestureDetector(
              onTap: _showAddDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Tambah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (_courses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Belum ada mata kuliah.',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ..._courses.map(_buildCourseCard),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withAlpha(15),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.sage,
            child: Text(
              ((c['code'] as String?) ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c['code']} - ${c['name']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Semester ${c['semester']} · ${c['credits']} SKS',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                if ((c['description'] as String?)?.isNotEmpty == true)
                  Text(
                    c['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.body),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
            onPressed: () => _deleteCourse(c),
          ),
        ],
      ),
    );
  }
}

class _CourseFormDialog extends StatefulWidget {
  const _CourseFormDialog();

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _semester;
  late final TextEditingController _credits;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _name = TextEditingController();
    _semester = TextEditingController(text: '1');
    _credits = TextEditingController(text: '3');
    _description = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _semester.dispose();
    _credits.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Tambah Mata Kuliah',
        style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildField(_code, 'Kode MK', hint: 'BING101'),
            const SizedBox(height: 10),
            _buildField(_name, 'Nama Mata Kuliah'),
            const SizedBox(height: 10),
            _buildField(_semester, 'Semester', number: true),
            const SizedBox(height: 10),
            _buildField(_credits, 'SKS', number: true),
            const SizedBox(height: 10),
            _buildField(_description, 'Deskripsi (opsional)', maxLines: 2),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.muted))),
        GestureDetector(
          onTap: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'code': _code.text.trim().toUpperCase(),
                'name': _name.text.trim(),
                'semester': _semester.text.trim(),
                'credits': _credits.text.trim(),
                'description': _description.text.trim(),
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {bool number = false, int maxLines = 1, String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.cream2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
      validator: (v) {
        if (label == 'Kode MK' || label == 'Nama Mata Kuliah') {
          return (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null;
        }
        if (number && v?.isNotEmpty == true && int.tryParse(v!) == null) {
          return 'Harus angka';
        }
        return null;
      },
    );
  }
}

// ==================== MODULES TAB ====================

class _ModulesTab extends ConsumerStatefulWidget {
  const _ModulesTab();
  @override
  ConsumerState<_ModulesTab> createState() => _ModulesTabState();
}

class _ModulesTabState extends ConsumerState<_ModulesTab> {
  List<dynamic> _modules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _modules = await ref.read(adminServiceProvider).getModules();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.response?.data is Map) {
      return e.response?.data['detail']?.toString() ?? 'Terjadi kesalahan';
    }
    return e.toString();
  }

  Future<void> _approve(dynamic m) async {
    try {
      await ref.read(adminServiceProvider).approveModule(m['id']);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyetujui: ${_errorMessage(e)}')));
      }
    }
  }

  Future<void> _reject(dynamic m) async {
    try {
      await ref.read(adminServiceProvider).rejectModule(m['id']);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menolak: ${_errorMessage(e)}')));
      }
    }
  }

  Future<void> _publish(dynamic m) async {
    try {
      await ref.read(adminServiceProvider).publishModule(m['id']);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menerbitkan: ${_errorMessage(e)}')));
      }
    }
  }

  void _confirmPublish(dynamic m) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terbitkan Modul?',
          style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${m['title']}" akan langsung diterbitkan.',
              style: const TextStyle(color: AppColors.body),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: 'Catatan (opsional)',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.cream2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              _publish(m);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Terbitkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.green));
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Gagal memuat modul', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ]),
      );
    }

    final review = _modules.where((m) => m['status'] == 'review').toList();
    final published = _modules.where((m) => m['status'] == 'published').toList();
    final draft = _modules.where((m) => m['status'] == 'draft').toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (review.isNotEmpty) ...[
            _buildSectionTitle('Menunggu Review (${review.length})', AppColors.yellow),
            const SizedBox(height: 8),
            ...review.map((m) => _buildModuleCard(m, isReview: true)),
            const SizedBox(height: 16),
          ],
          if (draft.isNotEmpty) ...[
            _buildSectionTitle('Draft (${draft.length})', AppColors.muted),
            const SizedBox(height: 8),
            ...draft.map((m) => _buildModuleCard(m, isDraft: true)),
            const SizedBox(height: 16),
          ],
          if (published.isNotEmpty) ...[
            _buildSectionTitle('Diterbitkan (${published.length})', AppColors.green),
            const SizedBox(height: 8),
            ...published.map((m) => _buildModuleCard(m, isPublished: true)),
          ],
          if (review.isEmpty && published.isEmpty && draft.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Belum ada modul.', style: TextStyle(color: AppColors.muted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(dynamic m,
      {bool isReview = false, bool isDraft = false, bool isPublished = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withAlpha(15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m['title'] ?? '-',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oleh: ${m['creator_name'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: AppColors.body),
          ),
          if ((m['review_note'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.yellow.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                m['review_note'],
                style: const TextStyle(fontSize: 11, color: AppColors.body),
              ),
            ),
          ],
          if (isReview || isDraft) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isReview) ...[
                  _buildActionChip(
                    icon: Icons.check,
                    label: 'Setujui',
                    color: AppColors.green,
                    onTap: () => _approve(m),
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    icon: Icons.close,
                    label: 'Tolak',
                    color: AppColors.red,
                    onTap: () => _reject(m),
                  ),
                ],
                if (isDraft) ...[
                  _buildActionChip(
                    icon: Icons.publish,
                    label: 'Terbitkan',
                    color: AppColors.green,
                    onTap: () => _confirmPublish(m),
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    icon: Icons.close,
                    label: 'Tolak',
                    color: AppColors.red,
                    onTap: () => _reject(m),
                  ),
                ],
                if (isPublished) ...[
                  _buildActionChip(
                    icon: Icons.close,
                    label: 'Tolak',
                    color: AppColors.red,
                    onTap: () => _reject(m),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MONITORING TAB ====================

const _roleColors = <String, Color>{
  'mahasiswa': AppColors.green,
  'dosen': AppColors.yellow,
  'super_admin': AppColors.sage,
  'superAdmin': AppColors.sage,
};

const _moduleStatusColors = <String, Color>{
  'draft': AppColors.muted,
  'review': AppColors.yellow,
  'published': AppColors.green,
};

class _MonitoringTab extends ConsumerStatefulWidget {
  const _MonitoringTab();
  @override
  ConsumerState<_MonitoringTab> createState() => _MonitoringTabState();
}

class _MonitoringTabState extends ConsumerState<_MonitoringTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _stats = await ref.read(adminServiceProvider).getStats();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.green));
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.body)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }
    if (_stats == null) return const SizedBox.shrink();

    final totalUsers = _stats!['total_users'] ?? 0;
    final totalCourses = _stats!['total_courses'] ?? 0;
    final totalModules = _stats!['total_modules'] ?? 0;
    final totalInteractions = _stats!['total_interactions'] ?? 0;
    final avgScore = (_stats!['avg_score'] as num?)?.toDouble() ?? 0;
    final usersByRole = (_stats!['users_by_role'] as List?) ?? [];
    final modulesByStatus = (_stats!['modules_by_status'] as List?) ?? [];
    final dailyActivity = (_stats!['daily_activity'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          const Text(
            'Monitoring Sistem',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _StatCard(label: 'Total Pengguna', value: '$totalUsers')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Mata Kuliah', value: '$totalCourses')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(label: 'Total Modul', value: '$totalModules')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Interaksi', value: '$totalInteractions')),
          ]),
          const SizedBox(height: 12),
          _StatCard(label: 'Rata-rata Skor', value: avgScore.toStringAsFixed(1)),

          const SizedBox(height: 24),
          const Text(
            'Pengguna per Role',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          if (usersByRole.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withAlpha(15),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 180,
                      child: PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: usersByRole.map((r) {
                          final role = r['role'] as String;
                          final count = (r['count'] as num).toDouble();
                          return PieChartSectionData(
                            value: count,
                            color: _roleColors[role] ?? AppColors.muted,
                            radius: 50,
                            title: count.toInt().toString(),
                            titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        }).toList(),
                      )),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: usersByRole.map((r) {
                        final role = r['role'] as String;
                        final count = r['count'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _roleColors[role] ?? AppColors.muted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(role, style: const TextStyle(fontSize: 13, color: AppColors.body))),
                            Text('$count',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildEmptyCard('Belum ada data pengguna.'),

          const SizedBox(height: 24),
          const Text(
            'Modul per Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          if (modulesByStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withAlpha(15),
                  ),
                ],
              ),
              child: SizedBox(
                height: 200,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (modulesByStatus
                              .map((m) => (m['count'] as num).toDouble())
                              .fold<double>(0, (a, b) => a > b ? a : b) *
                          1.3)
                      .clamp(4, double.infinity),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        final status = modulesByStatus[group.x.toInt()]['status'];
                        return BarTooltipItem(
                          '$status\n',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()} modul',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= modulesByStatus.length) {
                            return const SizedBox.shrink();
                          }
                          final s = modulesByStatus[idx]['status'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.body)),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) return const SizedBox.shrink();
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.body));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: modulesByStatus.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final count = (entry.value['count'] as num).toDouble();
                    final status = entry.value['status'] as String;
                    return BarChartGroupData(x: idx, barRods: [
                      BarChartRodData(
                        toY: count,
                        color: _moduleStatusColors[status] ?? AppColors.muted,
                        width: 36,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ]);
                  }).toList(),
                )),
              ),
            )
          else
            _buildEmptyCard('Belum ada data modul.'),

          const SizedBox(height: 24),
          const Text(
            'Aktivitas Harian (14 Hari Terakhir)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          if (dailyActivity.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withAlpha(15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: LineChart(LineChartData(
                      minY: 0,
                      maxY: (dailyActivity
                                  .map((d) => (d['interactions'] as num).toDouble())
                                  .fold<double>(0, (a, b) => a > b ? a : b) *
                              1.3)
                          .clamp(4, double.infinity),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: (dailyActivity.length / 6).ceilToDouble().clamp(1, double.infinity),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= dailyActivity.length) return const SizedBox.shrink();
                              final date = dailyActivity[idx]['date'] as String;
                              final short = date.length >= 5 ? date.substring(5) : date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(short, style: const TextStyle(fontSize: 10, color: AppColors.body)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value != value.roundToDouble()) return const SizedBox.shrink();
                              return Text('${value.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.body));
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyActivity.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              (e.value['interactions'] as num).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppColors.green,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.green.withAlpha(30),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              final date = dailyActivity[idx]['date'] ?? '';
                              final interactions = dailyActivity[idx]['interactions'];
                              return LineTooltipItem(
                                '$date\n',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                    text: '$interactions interaksi',
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 10, color: AppColors.green),
                      SizedBox(width: 6),
                      Text('Jumlah Interaksi', style: TextStyle(fontSize: 12, color: AppColors.body)),
                    ],
                  ),
                ],
              ),
            )
          else
            _buildEmptyCard('Belum ada data aktivitas.'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: AppColors.muted))),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withAlpha(15),
          ),
        ],
      ),
      child: Column(children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.body),
        ),
      ]),
    );
  }
}

// ==================== KELAS TAB ====================

class _KelasTab extends ConsumerStatefulWidget {
  const _KelasTab();
  @override
  ConsumerState<_KelasTab> createState() => _KelasTabState();
}

class _KelasTabState extends ConsumerState<_KelasTab> {
  List<dynamic> _kelasList = [];
  List<dynamic> _dosenList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ref.read(adminServiceProvider).getKelas(),
        ref.read(adminServiceProvider).getUsers(),
      ]);
      _kelasList = results[0];
      _dosenList = (results[1] as List<dynamic>)
          .where((u) => u['role'] == 'dosen')
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.response?.data is Map) {
      return e.response?.data['detail']?.toString() ?? 'Terjadi kesalahan';
    }
    return e.toString();
  }

  String? _dosenName(int? dosenId) {
    if (dosenId == null) return null;
    try {
      final d = _dosenList.firstWhere((u) => u['id'] == dosenId);
      return d['full_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KelasFormDialog(dosenList: _dosenList),
    );
    if (result == null) return;
    try {
      await ref.read(adminServiceProvider).createKelas(
            name: result['name'] as String,
            dosenId: result['dosen_id'] as int?,
            description: result['description'] as String?,
          );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${_errorMessage(e)}')));
      }
    }
  }

  Future<void> _showEditDialog(dynamic k) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _KelasFormDialog(
        dosenList: _dosenList,
        initialName: k['name'] as String?,
        initialDosenId: k['dosen_id'] as int?,
        initialDescription: k['description'] as String?,
        isEdit: true,
      ),
    );
    if (result == null) return;
    try {
      await ref.read(adminServiceProvider).updateKelas(k['id'] as int, {
        'name': result['name'] as String,
        'dosen_id': result['dosen_id'],
        'description': result['description'] as String?,
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${_errorMessage(e)}')));
      }
    }
  }

  Future<void> _deleteKelas(dynamic k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus ${k['name']}?',
          style: const TextStyle(
              color: AppColors.dark, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Kelas akan dihapus permanen.',
          style: TextStyle(color: AppColors.body),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.muted))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminServiceProvider).deleteKelas(k['id'] as int);
      setState(() {
        _kelasList.removeWhere((item) => item['id'] == k['id']);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${_errorMessage(e)}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.body)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(children: [
            Expanded(
              child: Text(
                'Kelas (${_kelasList.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
            GestureDetector(
              onTap: _showAddDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Tambah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (_kelasList.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Belum ada kelas.',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ..._kelasList.map(_buildKelasCard),
        ],
      ),
    );
  }

  Widget _buildKelasCard(dynamic k) {
    final dosen = _dosenName(k['dosen_id'] as int?);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withAlpha(15),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: Color(0xFF1565C0), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                if (dosen != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Dosen: $dosen',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.body),
                  ),
                ],
                if (k['description'] != null &&
                    (k['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    k['description'] as String,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.greenDark),
            onPressed: () => _showEditDialog(k),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.red),
            onPressed: () => _deleteKelas(k),
          ),
        ],
      ),
    );
  }
}

class _KelasFormDialog extends StatefulWidget {
  final List<dynamic> dosenList;
  final String? initialName;
  final int? initialDosenId;
  final String? initialDescription;
  final bool isEdit;

  const _KelasFormDialog({
    required this.dosenList,
    this.initialName,
    this.initialDosenId,
    this.initialDescription,
    this.isEdit = false,
  });

  @override
  State<_KelasFormDialog> createState() => _KelasFormDialogState();
}

class _KelasFormDialogState extends State<_KelasFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  int? _selectedDosenId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _description =
        TextEditingController(text: widget.initialDescription ?? '');
    _selectedDosenId = widget.initialDosenId;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isEdit ? 'Edit Kelas' : 'Tambah Kelas',
        style: const TextStyle(
            color: AppColors.dark, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(_name, 'Nama Kelas'),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedDosenId,
                decoration: InputDecoration(
                  labelText: 'Dosen (opsional)',
                  labelStyle: const TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.cream2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.green, width: 1.5),
                  ),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Tanpa dosen',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                  ...widget.dosenList.map<DropdownMenuItem<int>>((d) {
                    return DropdownMenuItem<int>(
                      value: d['id'] as int,
                      child: Text(d['full_name'] as String? ?? ''),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _selectedDosenId = v),
              ),
              const SizedBox(height: 10),
              _buildField(_description, 'Deskripsi (opsional)',
                  maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.muted))),
        GestureDetector(
          onTap: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'dosen_id': _selectedDosenId,
                'description': _description.text.trim(),
              });
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Simpan',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.cream2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
      validator: (v) {
        if (label == 'Nama Kelias') {
          return (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null;
        }
        return null;
      },
    );
  }
}
