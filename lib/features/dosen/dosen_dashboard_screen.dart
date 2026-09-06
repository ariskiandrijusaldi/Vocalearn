import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/dosen_service.dart';
import 'edit_module_screen.dart';
import 'material_detail_screen.dart';

class DosenDashboardScreen extends ConsumerStatefulWidget {
  const DosenDashboardScreen({super.key});

  @override
  ConsumerState<DosenDashboardScreen> createState() =>
      _DosenDashboardScreenState();
}

class _DosenDashboardScreenState extends ConsumerState<DosenDashboardScreen> {
  List<dynamic> _modules = [];
  List<dynamic> _students = [];
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final results = await Future.wait([
        DosenService().getMyModules(),
        DosenService().getStudents(),
        DosenService().getDosenLeaderboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _modules = results[0];
        _students = results[1];
        _leaderboard = results[2];
      });
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DosenService().getMyModules(),
        DosenService().getStudents(),
        DosenService().getDosenLeaderboard(),
      ]);
      setState(() {
        _modules = results[0];
        _students = results[1];
        _leaderboard = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'draft' => Colors.orange,
      'review' => Colors.blue,
      'published' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'draft' => 'Draft',
      'review' => 'Review',
      'published' => 'Diterbitkan',
      _ => status,
    };
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'Belum aktif';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return 'Belum aktif';
    }
  }

  Future<void> _deleteModule(dynamic item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus "${item['title']}"?',
          style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Modul akan dihapus secara permanen.',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black38)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DosenService().deleteModule(item['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modul berhasil dihapus'), backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      String msg = 'Gagal menghapus modul';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['detail']?.toString() ?? msg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  List<Widget> _buildGroupedStudents() {
    final map = <String, List<dynamic>>{};
    for (final s in _students) {
      final kelas = (s['kelas_name'] ?? 'Tanpa Kelas').toString();
      map.putIfAbsent(kelas, () => []).add(s);
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final widgets = <Widget>[];
    for (final entry in sorted) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 4, top: 12),
          child: Row(
            children: [
              Icon(Icons.class_, size: 14, color: AppColors.dark.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                entry.key,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.dark.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${entry.value.length})',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
      for (final mhs in entry.value.take(5)) {
        final avg = (mhs['avg_score'] ?? 0.0) as num;
        final lastActive = mhs['last_active_at'] as String?;
        final activeLabel = _relativeTime(lastActive);
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.withAlpha(38),
                  child: const Icon(Icons.person, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mhs['full_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mhs['nim'] ?? mhs['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: activeLabel == 'Belum aktif'
                                ? Colors.black38
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: activeLabel == 'Belum aktif'
                                  ? Colors.black38
                                  : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${avg.toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildLeaderboard() {
    if (_leaderboard.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'Belum ada data peringkat.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final group in _leaderboard) {
      final kelasName = (group['kelas_name'] ?? 'Tanpa Kelas').toString();
      final entries = (group['entries'] as List<dynamic>? ?? []);

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 4, top: 12),
          child: Row(
            children: [
              Icon(Icons.class_, size: 14, color: AppColors.dark.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                kelasName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${entries.length})',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
      );

      for (final entry in entries) {
        final rank = (entry['rank'] as num?)?.toInt();
        final avg = (entry['average_score'] as num?)?.toDouble() ?? 0.0;
        final attempts = (entry['attempt_count'] as num?)?.toInt() ?? 0;
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank == null
                        ? AppColors.dark.withAlpha(20)
                        : rank == 1
                            ? AppColors.gold
                            : rank == 2
                                ? AppColors.muted
                                : rank == 3
                                    ? AppColors.yellow
                                    : AppColors.dark.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    rank?.toString() ?? '-',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: rank != null && rank <= 3
                          ? Colors.white
                          : AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['full_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry['nim'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.dark,
                      ),
                    ),
                    Text(
                      '$attempts latihan',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(authProvider).user?.name ?? 'Dosen';
    final totalModules = _modules.length;
    final totalStudents = _students.length;
    final publishedCount =
        _modules.where((m) => m['status'] == 'published').length;

    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Greeting
                  Text(
                    'Halo, $userName 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selamat mengajar!',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Summary cards
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Modul',
                        count: '$totalModules',
                        icon: Icons.menu_book,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Diterbitkan',
                        count: '$publishedCount',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Mahasiswa',
                        count: '$totalStudents',
                        icon: Icons.groups,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recent modules
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modul Terakhir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_modules.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.folder_open, size: 40, color: Colors.black26),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada modul',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                  ..._modules.take(5).map((item) {
                    final status = item['status'] as String? ?? 'draft';
                    // Modul yang diunggah dosen langsung terbit; dosen tetap
                    // bisa mengedit/menghapus modul miliknya sendiri.
                    const canEdit = true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withAlpha(38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.menu_book,
                            color: _statusColor(status),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.dark,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (item['creator_name'] != null) item['creator_name'],
                            if (item['kelas_name'] != null) 'Kelas: ${item['kelas_name']}',
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withAlpha(38),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (canEdit) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: AppColors.dark,
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditModuleScreen(module: item),
                                    ),
                                  );
                                  _loadData();
                                },
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                color: Colors.red,
                                onPressed: () => _deleteModule(item),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaterialDetailScreen(module: item),
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 28),

                  // Recent students
                  const Text(
                    'Mahasiswa Terakhir',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_students.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Belum ada data mahasiswa.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),

                  ..._buildGroupedStudents(),

                  const SizedBox(height: 28),

                  // Papan Peringkat per kelas
                  const Text(
                    'Papan Peringkat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Diurutkan dari rata-rata nilai tertinggi ke terendah per kelas.',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 8),

                  ..._buildLeaderboard(),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, count;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
