import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/dosen_service.dart';

class EditModuleScreen extends StatefulWidget {
  final Map<String, dynamic> module;
  const EditModuleScreen({super.key, required this.module});

  @override
  State<EditModuleScreen> createState() => _EditModuleScreenState();
}

class _EditModuleScreenState extends State<EditModuleScreen> {
  late final TextEditingController _judul;
  late final TextEditingController _deskripsi;
  late final TextEditingController _konten;
  late final TextEditingController _youtubeUrl;
  late int _difficulty;
  int? _selectedCourseId;
  int? _selectedKelasId;
  bool _isLoading = false;
  bool _isLoadingCourses = true;
  List<dynamic> _courses = [];
  List<dynamic> _kelasList = [];
  File? _selectedPdf;
  String? _selectedPdfName;

  @override
  void initState() {
    super.initState();
    final m = widget.module;
    _judul = TextEditingController(text: m['title'] ?? '');
    _deskripsi = TextEditingController(text: m['description'] ?? '');
    _konten = TextEditingController(text: m['content'] ?? '');
    _youtubeUrl = TextEditingController(text: m['youtube_url'] ?? '');
    _difficulty = m['difficulty'] ?? 1;
    _selectedCourseId = m['course_id'] as int?;
    _selectedKelasId = m['kelas_id'] as int?;
    _loadCourses();
    _loadKelas();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await DosenService().getCourses();
      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadKelas() async {
    try {
      final kelas = await DosenService().getKelasList();
      setState(() => _kelasList = kelas);
    } catch (_) {}
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedPdf = File(result.files.first.path!);
        _selectedPdfName = result.files.first.name;
      });
    }
  }

  void _removePdf() {
    setState(() {
      _selectedPdf = null;
      _selectedPdfName = null;
    });
  }

  Future<void> _save() async {
    if (_judul.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul modul harus diisi')),
      );
      return;
    }
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = DosenService();
      final mod = await service.updateModule(
        widget.module['id'] as int,
        courseId: _selectedCourseId!,
        title: _judul.text.trim(),
        description: _deskripsi.text.trim().isEmpty ? null : _deskripsi.text.trim(),
        content: _konten.text.trim().isEmpty ? null : _konten.text.trim(),
        difficulty: _difficulty,
        youtubeUrl: _youtubeUrl.text.trim().isEmpty ? null : _youtubeUrl.text.trim(),
        kelasId: _selectedKelasId,
      );

      if (_selectedPdf != null) {
        try {
          await service.uploadModulePdf(mod['id'] as int, _selectedPdf!.path);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modul berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      String msg = 'Gagal memperbarui modul';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['detail']?.toString() ?? msg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Edit Modul'),
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingCourses
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Mata Kuliah',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedCourseId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Pilih mata kuliah'),
                    items: _courses
                        .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                              value: c['id'] as int,
                              child: Text('${c['code']} - ${c['name']}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCourseId = v),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Kelas',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedKelasId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Semua kelas (umum)'),
                    items: _kelasList
                        .map<DropdownMenuItem<int>>((k) => DropdownMenuItem(
                              value: k['id'] as int,
                              child: Text(k['name'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedKelasId = v),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Judul Modul',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _judul,
                  decoration: InputDecoration(
                    hintText: 'Masukkan judul modul',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _deskripsi,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Deskripsi singkat modul',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Konten Materi',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _konten,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Tulis konten materi pembelajaran di sini...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'File PDF (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                if (_selectedPdfName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedPdfName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _removePdf,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Pilih File PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dark,
                        side: const BorderSide(color: AppColors.dark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                const Text(
                  'Link YouTube (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _youtubeUrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://youtube.com/watch?v=...',
                    prefixIcon: const Icon(Icons.play_circle_outline, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Tingkat Kesulitan',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final level = i + 1;
                    final isSelected = _difficulty == level;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _difficulty = level),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.dark : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$level',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.dark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    _konten.dispose();
    _youtubeUrl.dispose();
    super.dispose();
  }
}
