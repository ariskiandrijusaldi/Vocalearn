import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/repositories/dosen_service.dart';
import 'material_detail_screen.dart';

class DosenDashboardScreen extends ConsumerStatefulWidget {
  const DosenDashboardScreen({super.key});

  @override
  ConsumerState<DosenDashboardScreen> createState() =>
      _DosenDashboardScreenState();
}

class _DosenDashboardScreenState extends ConsumerState<DosenDashboardScreen> {
  static const navy = Color(0xFF0F414A);

  List<dynamic> _modules = [];
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DosenService().getMyModules(),
        DosenService().getStudents(),
      ]);
      setState(() {
        _modules = results[0];
        _students = results[1];
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
                      color: navy,
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
                          color: navy,
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
                            color: navy,
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
                        trailing: Container(
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
                      color: navy,
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

                  ..._students.take(5).map((mhs) {
                    final avg = (mhs['avg_score'] ?? 0.0) as num;
                    return Container(
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
                                    color: navy,
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
                                if (mhs['kelas_name'] != null)
                                  Text(
                                    'Kelas: ${mhs['kelas_name']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: navy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${avg.toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: navy,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
