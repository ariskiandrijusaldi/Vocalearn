import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class DosenProfileScreen extends ConsumerStatefulWidget {
  const DosenProfileScreen({super.key});

  @override
  ConsumerState<DosenProfileScreen> createState() =>
      _DosenProfileScreenState();
}

class _DosenProfileScreenState
    extends ConsumerState<DosenProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _mataKuliahController = TextEditingController();
  final _kelasController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _mataKuliahController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  void _simpanProfil() {
    if (_formKey.currentState!.validate()) {
      // TODO:
      // Kirim data ke provider profil dosen
      // setelah provider dari Arrizki tersedia.

      context.go('/dosen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // =========================
                // HEADER
                // =========================
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.dark,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DOSEN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // =========================
                // VOCaLEARN LOGO / TITLE
                // =========================
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.dark,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VocaLearn',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Adaptive Learning Platform',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // =========================
                // WELCOME TEXT
                // =========================
                const Text(
                  'Lengkapi Profil Dosen 👋',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Masukkan informasi dosen dan kelas yang Anda ampu untuk mendapatkan pengalaman VocaLearn yang lebih personal.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 25),

                // =========================
                // PROFILE CARD
                // =========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      // Profile icon
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                color: AppColors.sage.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 45,
                                color: AppColors.dark,
                              ),
                            ),

                            Positioned(
                              right: 0,
                              bottom: 2,
                              child: Container(
                                width: 27,
                                height: 27,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 13,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // =========================
                      // NAMA DOSEN
                      // =========================
                      _buildLabel(
                        'Nama Dosen',
                        Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 8),

                      _buildTextField(
                        controller: _namaController,
                        hintText: 'Contoh: Mutiara Azizah Yuzar',
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Nama dosen wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // MATA KULIAH
                      // =========================
                      _buildLabel(
                        'Mata Kuliah yang Diampu',
                        Icons.menu_book_outlined,
                      ),

                      const SizedBox(height: 8),

                      _buildTextField(
                        controller: _mataKuliahController,
                        hintText:
                        'Contoh: Praktik Pemrograman Dasar',
                        icon: Icons.menu_book_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Mata kuliah wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // KELAS
                      // =========================
                      _buildLabel(
                        'Kelas yang Diampu',
                        Icons.groups_outlined,
                      ),

                      const SizedBox(height: 8),

                      _buildTextField(
                        controller: _kelasController,
                        hintText: 'Contoh: MI-2B',
                        icon: Icons.groups_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Kelas wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // =========================
                      // BUTTON
                      // =========================
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _simpanProfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                'Simpan & Lanjutkan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =========================
                // INFO
                // =========================
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.sage.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.dark,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data ini digunakan untuk menyesuaikan dashboard dan pemantauan kompetensi mahasiswa.',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // LABEL
  // =========================
  Widget _buildLabel(
      String text,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.dark,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // =========================
  // TEXT FIELD
  // =========================
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(
        color: AppColors.dark,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.dark,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.cream.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.sage,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.red,
            width: 1,
          ),
        ),
      ),
    );
  }
}