import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';

/// ==========================================================
/// TRACK SUPER ADMIN — PIC: Arrizki Andri Jusaldi
/// ==========================================================
/// Terhubung ke to-do list bagian:
///   §9 Panel Super Admin / Administrasi
///
/// TODO selanjutnya untuk track ini:
///   [ ] Buat UserManagementScreen (CRUD mahasiswa & dosen)
///   [ ] Buat MataKuliahManagementScreen (mapping SKKNI/KKNI)
///   [ ] Buat ModuleApprovalScreen (draft -> review -> published)
///   [ ] Buat SystemMonitoringScreen (angka & chart pemakaian platform)
///   [ ] Buat IntegrationSettingsScreen (status dummy SIAKAD/LSP)
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    final menuItems = [
      (icon: Icons.people_outline, title: 'Manajemen Pengguna',
      subtitle: 'CRUD akun mahasiswa & dosen'),
      (icon: Icons.menu_book_outlined, title: 'Manajemen Mata Kuliah',
      subtitle: 'Mapping SKKNI/KKNI per prodi'),
      (icon: Icons.fact_check_outlined, title: 'Approval Modul Praktik',
      subtitle: 'Review modul sebelum tayang ke mahasiswa'),
      (icon: Icons.query_stats_outlined, title: 'Monitoring Sistem',
      subtitle: 'Pengguna aktif & pemakaian platform'),
      (icon: Icons.hub_outlined, title: 'Integrasi Eksternal',
      subtitle: 'Status SIAKAD & LSP (demo)'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('VocaLearn — Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Halo, ${user?.name ?? 'Admin'} 👋',
              style: Theme.of(context).textTheme.titleLarge),
          const Text('Ringkasan sistem VocaLearn (data dummy).'),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _StatCard(label: 'Mahasiswa Aktif', value: '128')),
              SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Dosen', value: '14')),
              SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Mata Kuliah', value: '9')),
            ],
          ),
          const SizedBox(height: 20),
          Text('Menu Administrasi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...menuItems.map(
                (m) => Card(
              child: ListTile(
                leading: Icon(m.icon),
                title: Text(m.title),
                subtitle: Text(m.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: navigasi ke masing-masing screen di atas
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}