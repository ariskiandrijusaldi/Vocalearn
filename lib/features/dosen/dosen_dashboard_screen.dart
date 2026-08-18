import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';

/// ==========================================================
/// TRACK DOSEN — PIC: Mutiara Azizah Yuzar
/// ==========================================================
/// Terhubung ke to-do list bagian:
///   §8 Dashboard Analitik Dosen
///
/// TODO selanjutnya untuk track ini:
///   [ ] Buat StudentListScreen dengan indikator hijau/kuning/merah
///   [ ] Buat ClassCompetencyChart (agregat, pakai fl_chart)
///   [ ] Buat StudentDetailScreen (riwayat modul per mahasiswa)
///   [ ] Ganti _dummyStudents dengan data dari API dashboard dosen
class DosenDashboardScreen extends ConsumerWidget {
  const DosenDashboardScreen({super.key});

  static const _dummyStudents = [
    (name: 'Alya Khairunnisa', avgMastery: 0.82, status: 'Aman'),
    (name: 'Mutiara Azizah', avgMastery: 0.41, status: 'Perlu Intervensi'),
    (name: 'Arrizki Andri', avgMastery: 0.63, status: 'Dalam Proses'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VocaLearn — Dashboard Dosen'),
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
          Text('Halo, ${user?.name ?? 'Dosen'} 👋',
              style: Theme.of(context).textTheme.titleLarge),
          const Text('Kelas: Praktik Jaringan Komputer (dummy)'),
          const SizedBox(height: 20),

          Text('Peta Kompetensi Kelas (Agregat)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Placeholder(
                fallbackHeight: 140,
                // TODO: ganti dengan chart fl_chart (radar/bar) agregat kelas
                child: Center(child: Text('Chart agregat kompetensi kelas')),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text('Daftar Mahasiswa', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._dummyStudents.map(
                (s) => Card(
              child: ListTile(
                title: Text(s.name),
                subtitle: LinearProgressIndicator(value: s.avgMastery),
                trailing: _StatusChip(status: s.status),
                onTap: () {
                  // TODO: navigasi ke StudentDetailScreen
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Aman' => Colors.green,
      'Dalam Proses' => Colors.orange,
      _ => Colors.red,
    };
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}