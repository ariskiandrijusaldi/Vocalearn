import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../auth/change_password_dialog.dart';
import 'dosen_dashboard_screen.dart';
import 'upload_materi_screen.dart';
import 'student_list_screen.dart';

class DosenShell extends ConsumerStatefulWidget {
  const DosenShell({super.key});

  @override
  ConsumerState<DosenShell> createState() => _DosenShellState();
}

class _DosenShellState extends ConsumerState<DosenShell> {
  int _currentIndex = 0;

  static const _labels = ['Beranda', 'Upload', 'Mahasiswa', 'Profil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.upload_file_outlined,
    Icons.groups_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.home,
    Icons.upload_file,
    Icons.groups,
    Icons.person,
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
                  (user?.name ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.name ?? 'Dosen',
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
    return Scaffold(
      backgroundColor: const Color(0xFFEFE8DF),
      body: switch (_currentIndex) {
        0 => const DosenDashboardScreen(),
        1 => const UploadMateriScreen(),
        2 => const StudentListScreen(),
        _ => const SizedBox.shrink(),
      },
      bottomNavigationBar: Container(
        height: 77,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
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
          children: List.generate(4, (i) {
            final active = _currentIndex == i;
            return GestureDetector(
              onTap: () {
                if (i == 3) {
                  _showProfileMenu();
                } else if (_currentIndex != i) {
                  setState(() => _currentIndex = i);
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
