import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/refresh_provider.dart';
import '../auth/change_password_dialog.dart';
import 'mahasiswa_home_screen.dart';
import 'module_list_screen.dart';
import 'nilai_screen.dart';
import 'progress_screen.dart';

class MahasiswaShell extends ConsumerStatefulWidget {
  const MahasiswaShell({super.key});

  @override
  ConsumerState<MahasiswaShell> createState() => _MahasiswaShellState();
}

class _MahasiswaShellState extends ConsumerState<MahasiswaShell> {
  int _currentIndex = 0;

  static const _labels = ['Beranda', 'Modul', 'Nilai', 'Progress', 'Profil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.article_outlined,
    Icons.grading_outlined,
    Icons.bar_chart_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.home,
    Icons.article,
    Icons.grading,
    Icons.bar_chart,
    Icons.person,
  ];

  static const _pages = [
    MahasiswaHomeScreen(),
    ModuleListScreen(),
    NilaiScreen(),
    ProgressScreen(),
    SizedBox.shrink(),
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
                  (user?.name ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.name ?? 'Mahasiswa',
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
              const SizedBox(height: 12),
              if (user?.kelasName != null || user?.prodi != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Prodi ditampilkan lebih dulu ---
                      if (user?.prodi != null)
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 16, color: AppColors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Prodi: ${user!.prodi}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                      if (user?.kelasName != null && user?.prodi != null)
                        const SizedBox(height: 6),
                      // --- Kelas ditampilkan di bawah Prodi ---
                      if (user?.kelasName != null)
                        Row(
                          children: [
                            const Icon(Icons.class_, size: 16, color: AppColors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Kelas: ${user!.kelasName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
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
      backgroundColor: AppColors.cream,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 77,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
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
            final active = _currentIndex == i;
            return GestureDetector(
              onTap: () {
                if (i == 4) {
                  _showProfileMenu();
                } else if (_currentIndex != i) {
                  setState(() => _currentIndex = i);
                  if (i == 0) {
                    ref.read(homeRefreshProvider.notifier).state++;
                  }
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
