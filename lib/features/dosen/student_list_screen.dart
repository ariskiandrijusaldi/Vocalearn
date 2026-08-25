import 'package:flutter/material.dart';

import 'student_detail_screen.dart';
import '../../data/repositories/dosen_service.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  static const cream = Color(0xFFEFE8DF);
  static const navy = Color(0xFF0F414A);

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
        final q = query.toLowerCase();
        return name.contains(q) || nim.contains(q) || email.contains(q);
      }).toList();
    });
  }

  Color _statusColor(double avgScore) {
    if (avgScore >= 70) return const Color(0xFF0F414A);
    if (avgScore >= 40) return const Color(0xFFDBA98A);
    return const Color(0xFF7F0303);
  }

  String _statusLabel(double avgScore) {
    if (avgScore >= 70) return 'Dikuasai';
    if (avgScore >= 40) return 'Perlu Bantuan';
    return 'Tertinggal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
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
                          color: navy,
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
                  icon: Icon(Icons.search, color: navy),
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
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final mhs = _filteredStudents[index];
                              final avgScore =
                                  (mhs['avg_score'] ?? 0.0) as num;
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
                            },
                          ),
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
                    color: navy,
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
                    style: const TextStyle(fontSize: 11, color: navy, fontWeight: FontWeight.w600),
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
                  color: navy,
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
