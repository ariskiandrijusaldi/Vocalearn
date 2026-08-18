import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/module_provider.dart';

/// ==========================================================
/// TRACK MAHASISWA — Langkah 6a: Daftar Modul Praktik
/// ==========================================================
/// Terhubung ke to-do list §6 & Mini-PRD Fitur 2.
/// Acceptance criteria: list modul menunjukkan status berbeda
/// (terkunci/direkomendasikan/selesai).
class ModuleListScreen extends ConsumerWidget {
  const ModuleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(moduleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modul Praktik')),
      body: modules.isEmpty
          ? const Center(child: Text('Belum ada modul tersedia.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          final isLocked = module.status == ModuleStatus.terkunci;

          return Card(
            child: ListTile(
              leading: _StatusIcon(status: module.status),
              title: Text(module.title),
              subtitle: Text(module.description),
              trailing: _StatusLabel(status: module.status),
              enabled: !isLocked,
              onTap: isLocked
                  ? null
                  : () => context.go('/mahasiswa/modules/${module.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final ModuleStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ModuleStatus.terkunci => const Icon(Icons.lock_outline, color: Colors.grey),
      ModuleStatus.direkomendasikan =>
          Icon(Icons.play_circle_outline, color: Theme.of(context).colorScheme.primary),
      ModuleStatus.selesai => const Icon(Icons.check_circle, color: Colors.green),
    };
  }
}

class _StatusLabel extends StatelessWidget {
  final ModuleStatus status;
  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ModuleStatus.terkunci => ('Terkunci', Colors.grey),
      ModuleStatus.direkomendasikan => ('Direkomendasikan', Colors.blue),
      ModuleStatus.selesai => ('Selesai', Colors.green),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}