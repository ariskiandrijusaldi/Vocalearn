import 'package:flutter/material.dart';

import '../../../../domain/entities/course.dart';
import '../../../../domain/entities/practice_module.dart';

class ModuleApprovalList extends StatelessWidget {
  const ModuleApprovalList({
    super.key,
    required this.modules,
    required this.courses,
    required this.onApprove,
    required this.onReject,
  });

  final List<PracticeModule> modules;
  final List<Course> courses;
  final Future<void> Function(PracticeModule module) onApprove;
  final Future<void> Function(PracticeModule module) onReject;

  String _courseName(int courseId) {
    for (final course in courses) {
      if (course.id == courseId) return course.name;
    }
    return 'Mata Kuliah #$courseId';
  }

  Color _statusColor(ModuleStatus status) {
    return switch (status) {
      ModuleStatus.draft => Colors.grey,
      ModuleStatus.review => Colors.orange,
      ModuleStatus.published => Colors.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return const Center(child: Text('Belum ada modul.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: modules.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final module = modules[index];
        final isReview = module.status == ModuleStatus.review;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(module.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        module.status.label,
                        style: TextStyle(
                          color: _statusColor(module.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_courseName(module.courseId)} • Tingkat ${module.difficulty}/5',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (module.reviewNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Catatan review: ${module.reviewNote}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (isReview) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => onApprove(module),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Setujui'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => onReject(module),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tolak'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
