import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/dosen_service.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await DosenService().getStudents();
      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _filteredStudents = _students.where((s) {
        final name = (s['full_name'] ?? '').toString().toLowerCase();
        final nim = (s['nim'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        final kelas = (s['kelas_name'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || nim.contains(q) || email.contains(q) || kelas.contains(q);
      }).toList();
    });
  }

  Map<String, List<dynamic>> _groupByKelas(List<dynamic> students) {
    final map = <String, List<dynamic>>{};
    for (final s in students) {
      final kelas = (s['kelas_name'] ?? 'Tanpa Kelas').toString();
      map.putIfAbsent(kelas, () => []).add(s);
    }
    final sorted = Map<String, List<dynamic>>.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  Widget _buildGroupedList() {
    final grouped = _groupByKelas(_filteredStudents);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final kelasName = grouped.keys.elementAt(index);
        final students = grouped[kelasName]!;
        return _kelasSection(kelasName, students);
      },
    );
  }

  Widget _kelasSection(String kelasName, List<dynamic> students) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      initiallyExpanded: true,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.dark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.class_, size: 16, color: AppColors.dark),
                const SizedBox(width: 6),
                Text(
                  kelasName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${students.length} mahasiswa',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
      children: students.map((mhs) {
        final avgScore = (mhs['avg_score'] ?? 0.0) as num;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentDetailScreen(
                  studentId: mhs['id'] as int,
                ),
              ),
            );
          },
          child: _studentCard(mhs, avgScore.toDouble()),
        );
      }).toList(),
    );
  }

  Color _statusColor(double avgScore) {
    if (avgScore >= 70) return AppColors.green2;
    if (avgScore >= 40) return AppColors.yellow;
    return AppColors.red;
  }

  String _statusLabel(double avgScore) {
    if (avgScore >= 70) return 'Dikuasai';
    if (avgScore >= 40) return 'Perlu Bantuan';
    return 'Tertinggal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mahasiswa',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        'Monitoring kompetensi kelas',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStudents,
                decoration: const InputDecoration(
                  hintText: 'Cari mahasiswa...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.dark),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? const Center(child: Text('Tidak ada data mahasiswa'))
                      : RefreshIndicator(
                          onRefresh: _loadStudents,
                          child: _buildGroupedList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> mhs, double avgScore) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _statusColor(avgScore).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: _statusColor(avgScore)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mhs['full_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mhs['nim'] ?? mhs['email'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (mhs['kelas_name'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Kelas: ${mhs['kelas_name']}',
                    style: const TextStyle(fontSize: 11, color: AppColors.dark, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: avgScore / 100,
                    backgroundColor: Colors.black12,
                    color: _statusColor(avgScore),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '${avgScore.toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(avgScore),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(avgScore),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
