import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/competency.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/competency_provider.dart';

/// ==========================================================
/// TRACK MAHASISWA — PIC: Alya Khairunnisa
/// ==========================================================
/// Terhubung ke to-do list bagian:
///   §4 Modul Diagnostik Awal
///   §5 AI Adaptive Engine (sisi konsumsi rekomendasi)
///   §6 Modul Praktik Terpersonalisasi
///   §7 Progress & Gamifikasi
///
/// TODO selanjutnya untuk track ini:
///   [ ] Buat ModuleListScreen & ModuleDetailScreen (video, checklist, chat NLP)
///   [ ] Buat ProgressScreen (radar chart pakai fl_chart)
///   [ ] Ganti competencyProvider (lokal) dengan fetch dari AI Adaptive
///       Engine (§5 to-do list): GET /recommendation/{student_id}
class MahasiswaHomeScreen extends ConsumerWidget {
  const MahasiswaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final competencies = ref.watch(competencyProvider);
    final hasDiagnosticResult = competencies.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VocaLearn — Mahasiswa'),
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
          Text('Halo, ${user?.name ?? 'Mahasiswa'} 👋',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Berikut peta kompetensi & rekomendasi modul praktikmu.'),
          const SizedBox(height: 20),

          if (!hasDiagnosticResult) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Kamu belum mengisi diagnostik awal'),
                subtitle: const Text(
                    'Isi dulu supaya kami tahu titik mulai kompetensimu.'),
              ),
            ),
          ] else ...[
            Text('Peta Kompetensi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...competencies.map(
                  (c) => Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: LinearProgressIndicator(value: c.masteryScore),
                  trailing: _StatusChip(status: c.status),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.go('/mahasiswa/progress'),
              icon: const Icon(Icons.bar_chart_outlined),
              label: const Text('Lihat Progress & Lencana Lengkap'),
            ),
          ],

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/mahasiswa/modules'),
            icon: const Icon(Icons.play_lesson_outlined),
            label: const Text('Lanjutkan Modul yang Direkomendasikan'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/mahasiswa/diagnostic'),
            icon: const Icon(Icons.assignment_outlined),
            label: Text(hasDiagnosticResult
                ? 'Isi Ulang Diagnostik'
                : 'Isi Diagnostik Awal'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final CompetencyStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CompetencyStatus.dikuasai => (Colors.green, 'Dikuasai'),
      CompetencyStatus.dalamProses => (Colors.orange, 'Proses'),
      CompetencyStatus.perluIntervensi => (Colors.red, 'Perlu Bantuan'),
      CompetencyStatus.belumMulai => (Colors.grey, 'Belum Mulai'),
    };
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}