import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/dosen_service.dart';

class UploadMateriScreen extends ConsumerStatefulWidget {
  const UploadMateriScreen({super.key});

  @override
  ConsumerState<UploadMateriScreen> createState() => _UploadMateriScreenState();
}

class _UploadMateriScreenState extends ConsumerState<UploadMateriScreen> {
  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();
  final _konten = TextEditingController();
  final _youtubeUrl = TextEditingController();
  int _difficulty = 1;
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
    _loadCourses();
    _loadKelas();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await DosenService().getCourses();
      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses[0]['id'] as int;
        }
      });
    } catch (e) {
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadKelas() async {
    try {
      final kelas = await DosenService().getKelasList();
      setState(() => _kelasList = kelas);
    } catch (_) {
      // Biarkan kosong — field kelas bersifat opsional
    }
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

  void _resetForm() {
    _judul.clear();
    _deskripsi.clear();
    _konten.clear();
    _youtubeUrl.clear();
    _selectedPdf = null;
    _selectedPdfName = null;
    setState(() => _difficulty = 1);
  }

  Future<void> _upload() async {
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
      final mod = await service.createModule(
        courseId: _selectedCourseId!,
        title: _judul.text.trim(),
        description: _deskripsi.text.trim().isEmpty ? null : _deskripsi.text.trim(),
        content: _konten.text.trim().isEmpty ? null : _konten.text.trim(),
        difficulty: _difficulty,
        youtubeUrl: _youtubeUrl.text.trim().isEmpty ? null : _youtubeUrl.text.trim(),
        kelasId: _selectedKelasId,
      );

      // Modul sudah terbuat — kegagalan upload PDF tidak boleh dianggap gagal total.
      var pdfGagal = false;
      if (_selectedPdf != null) {
        try {
          await service.uploadModulePdf(mod['id'] as int, _selectedPdf!.path);
        } catch (_) {
          pdfGagal = true;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pdfGagal
                ? 'Modul dibuat, namun gagal mengunggah PDF'
                : 'Modul berhasil dibuat dan di publish'),
            backgroundColor: pdfGagal ? Colors.orange : Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      String msg = 'Gagal membuat modul';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['detail']?.toString() ?? msg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jurusanName = ref.watch(authProvider).user?.jurusanName;
    return SafeArea(
      child: _isLoadingCourses
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Upload Materi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                if (jurusanName != null && jurusanName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.account_tree_outlined,
                            size: 15, color: AppColors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Jurusan $jurusanName — hanya menampilkan mata '
                            'kuliah dari jurusan Anda',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Mata Kuliah',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 8),
                if (_courses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppColors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            jurusanName == null
                                ? 'Belum ada mata kuliah untuk diunggah'
                                : 'Belum ada mata kuliah untuk jurusan '
                                    '$jurusanName. Tambahkan lewat admin terlebih dahulu.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                if (_kelasList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppColors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Anda belum ditugaskan ke kelas manapun. '
                            'Modul akan bersifat umum untuk semua kelas.',
                            style: TextStyle(fontSize: 13, color: AppColors.dark),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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

                // PDF upload
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

                // YouTube link
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
                    onPressed: _isLoading ? null : _upload,
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
                            'Buat Modul',
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
