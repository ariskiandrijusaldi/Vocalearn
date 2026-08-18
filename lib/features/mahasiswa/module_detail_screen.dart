import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/assistant_provider.dart';
import '../../data/providers/module_provider.dart';

/// ==========================================================
/// TRACK MAHASISWA — Langkah 6b: Detail Modul Praktik
/// ==========================================================
/// Terhubung ke to-do list §6 & Mini-PRD Fitur 2.
/// Acceptance criteria:
///   - video demonstrasi (boleh dummy/placeholder untuk hackathon)
///   - checklist yang bisa dicentang
///   - setelah checklist selesai, status modul berubah jadi "selesai"
///   - asisten NLP: minimal 1 contoh nyata manggil API (lihat TODO
///     di assistant_provider.dart), sisanya boleh template
///
/// TODO selanjutnya (Alya):
///   [ ] Ganti _VideoPlaceholder dengan video_player/chewie sungguhan
///       kalau ada waktu — perhatikan video_player butuh setup platform
///       tambahan untuk Windows desktop (paket community terpisah,
///       plugin resmi belum tentu jalan langsung di Windows).
class ModuleDetailScreen extends ConsumerStatefulWidget {
  final String moduleId;
  const ModuleDetailScreen({super.key, required this.moduleId});

  @override
  ConsumerState<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  final Set<int> _checkedItems = {};
  final _messageController = TextEditingController();

  // Dipisah jadi fungsi sendiri (bukan loop langsung di build) supaya
  // hasilnya bisa disimpan sebagai `final module` di build() — variabel
  // `final` bisa di-promote null-safety-nya oleh Dart bahkan di dalam
  // closure (mis. onPressed), sedangkan variabel yang bisa diubah tidak bisa.
  PracticeModuleItem? _findModuleById(List<PracticeModuleItem> modules, String id) {
    for (final m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(moduleProvider);
    final module = _findModuleById(modules, widget.moduleId);

    if (module == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modul tidak ditemukan')),
        body: const Center(child: Text('Modul ini tidak tersedia.')),
      );
    }

    final allChecked = _checkedItems.length == module.checklistItems.length;
    final isAlreadyCompleted = module.status == ModuleStatus.selesai;

    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _VideoPlaceholder(),
          const SizedBox(height: 16),

          Text(module.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),

          Text('Checklist Praktik', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...List.generate(module.checklistItems.length, (index) {
            final checked = _checkedItems.contains(index) || isAlreadyCompleted;
            return CheckboxListTile(
              value: checked,
              title: Text(module.checklistItems[index]),
              onChanged: isAlreadyCompleted
                  ? null
                  : (value) {
                setState(() {
                  if (value == true) {
                    _checkedItems.add(index);
                  } else {
                    _checkedItems.remove(index);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 16),

          if (isAlreadyCompleted)
            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Modul ini sudah kamu selesaikan',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: !allChecked
                  ? null
                  : () {
                ref.read(moduleProvider.notifier).completeModule(module.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modul selesai! Kompetensimu diperbarui.')),
                );
                context.go('/mahasiswa');
              },
              icon: const Icon(Icons.check),
              label: const Text('Tandai Modul Selesai'),
            ),

          const SizedBox(height: 32),
          Text('Tanya Asisten Belajar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _AssistantChat(moduleId: module.id, controller: _messageController),
        ],
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                'Video demonstrasi (placeholder)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantChat extends ConsumerWidget {
  final String moduleId;
  final TextEditingController controller;
  const _AssistantChat({required this.moduleId, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(assistantChatProvider(moduleId));
    final chatController = ref.read(assistantChatProvider(moduleId).notifier);

    return Column(
      children: [
        if (messages.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Tanya seputar materi modul ini...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (text) {
                  chatController.sendMessage(text);
                  controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: () {
                chatController.sendMessage(controller.text);
                controller.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}