import 'package:flutter/material.dart';

import '../../../../domain/entities/course.dart';
import '../../../../domain/entities/learning_record.dart';
import '../../../../domain/entities/practice_module.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../../domain/repositories/recommendation_repository.dart';
import '../widgets/average_score_chart.dart';
import '../widgets/module_approval_list.dart';
import '../widgets/recommendation_panel.dart';
import '../widgets/user_form_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    super.key,
    required this.adminRepository,
    required this.recommendationRepository,
  });

  final AdminRepository adminRepository;
  final RecommendationRepository recommendationRepository;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loading = true;
  String? _error;
  List<User> _students = [];
  List<User> _lecturers = [];
  List<Course> _courses = [];
  List<PracticeModule> _modules = [];
  List<LearningRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
    _prefetchRecommendation();
  }

  Future<void> _prefetchRecommendation() async {
    try {
      final students = await widget.recommendationRepository.getStudents();
      if (students.isEmpty) return;
      await widget.recommendationRepository.getRecommendation(students.first.id);
    } catch (_) {
      // Prefetch best-effort: kalau gagal, tab Rekomendasi tetap jalan normal.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await widget.adminRepository.getStudents();
      final lecturers = await widget.adminRepository.getLecturers();
      final courses = await widget.adminRepository.getCourses();
      final modules = await widget.adminRepository.getModules();
      final records = await widget.adminRepository.getLearningRecords();
      if (!mounted) return;
      setState(() {
        _students = students;
        _lecturers = lecturers;
        _courses = courses;
        _modules = modules;
        _records = records;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _addUser(UserRole role) async {
    final result = await showUserFormDialog(context, role: role);
    if (result == null || !mounted) return;
    try {
      await widget.adminRepository.createUser(
        role: role,
        fullName: result.fullName,
        email: result.email,
        password: result.password,
        nim: result.nim,
        nip: result.nip,
        prodi: result.prodi,
      );
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _editUser(User user) async {
    final result = await showUserFormDialog(context, role: user.role, existing: user);
    if (result == null || !mounted) return;
    try {
      await widget.adminRepository.updateUser(
        user.copyWith(
          fullName: result.fullName,
          email: result.email,
          nim: result.nim,
          nip: result.nip,
          prodi: result.prodi,
        ),
      );
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${user.fullName}?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.adminRepository.deleteUser(user.id);
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _approveModule(PracticeModule module) async {
    try {
      await widget.adminRepository.approveModule(module.id);
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _rejectModule(PracticeModule module) async {
    try {
      await widget.adminRepository.rejectModule(module.id);
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  double _averageScore(int studentId) {
    final studentRecords =
        _records.where((r) => r.studentId == studentId).toList();
    if (studentRecords.isEmpty) return 0;
    return studentRecords.map((r) => r.score).reduce((a, b) => a + b) /
        studentRecords.length;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VocaLearn Super Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mahasiswa'),
              Tab(text: 'Dosen'),
              Tab(text: 'Modul'),
              Tab(text: 'Rekomendasi'),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    return TabBarView(
      children: [
        _buildStudentsTab(),
        _buildLecturersTab(),
        ModuleApprovalList(
          modules: _modules,
          courses: _courses,
          onApprove: _approveModule,
          onReject: _rejectModule,
        ),
        RecommendationPanel(
          repository: widget.recommendationRepository,
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Rata-rata Skor per Mahasiswa',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: AverageScoreChart(students: _students, records: _records),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Daftar Mahasiswa',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: () => _addUser(UserRole.student),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _students.isEmpty
              ? const Center(child: Text('Belum ada mahasiswa.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final average = _averageScore(student.id);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${student.nim ?? '-'} • ${student.prodi ?? '-'}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      student.email,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Rata-rata',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    average.toStringAsFixed(0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: 'Edit',
                              onPressed: () => _editUser(student),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              tooltip: 'Hapus',
                              onPressed: () => _deleteUser(student),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLecturersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text('Daftar Dosen',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: () => _addUser(UserRole.lecturer),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _lecturers.isEmpty
              ? const Center(child: Text('Belum ada dosen.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _lecturers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lecturer = _lecturers[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lecturer.fullName,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lecturer.nip ?? '-',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      lecturer.email,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                lecturer.prodi ?? '-',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: 'Edit',
                              onPressed: () => _editUser(lecturer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              tooltip: 'Hapus',
                              onPressed: () => _deleteUser(lecturer),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
