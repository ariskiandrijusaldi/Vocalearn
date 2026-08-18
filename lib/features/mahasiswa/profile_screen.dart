import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/student_profile_provider.dart';

/// ==========================================================
/// TRACK MAHASISWA — Langkah 3: Form Profil Mahasiswa
/// ==========================================================
/// Terhubung ke to-do list §3 & Mini-PRD Fitur 1 (bagian profil).
/// Acceptance criteria: field program studi & mata kuliah praktik yang
/// diambil (dropdown dari data dummy), disimpan ke state lokal dulu.
///
/// TODO selanjutnya (Alya):
///   [ ] Setelah tombol "Lanjut ke Diagnostik" ditekan, arahkan ke
///       DiagnosticScreen (langkah 4) begitu screen itu dibuat — ganti
///       context.go('/mahasiswa') di bawah.
///   [ ] Setelah backend siap, kirim data profil ke API juga (lihat
///       TODO di student_profile_provider.dart)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Data dummy — nanti bisa ditarik dari master data yang dikelola
  // Super Admin (§9), untuk sekarang cukup hardcode untuk demo.
  static const _daftarProdi = [
    'Manajemen Informatika',
    'Teknik Komputer',
    'Teknik Jaringan',
  ];

  static const _daftarMataKuliah = [
    'Praktik Jaringan Komputer',
    'Praktik Pemrograman Web',
  ];

  String? _selectedProdi;
  String? _selectedMataKuliah;

  @override
  Widget build(BuildContext context) {
    final isFormValid = _selectedProdi != null && _selectedMataKuliah != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Sebelum mulai, lengkapi dulu profil kamu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Informasi ini membantu VocaLearn menyesuaikan modul praktik yang tepat.',
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  initialValue: _selectedProdi,
                  decoration: const InputDecoration(labelText: 'Program Studi'),
                  items: _daftarProdi
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedProdi = value),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedMataKuliah,
                  decoration:
                  const InputDecoration(labelText: 'Mata Kuliah Praktik'),
                  items: _daftarMataKuliah
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedMataKuliah = value),
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: !isFormValid
                      ? null
                      : () {
                    ref.read(studentProfileProvider.notifier).save(
                      programStudi: _selectedProdi!,
                      mataKuliah: _selectedMataKuliah!,
                    );
                    context.go('/mahasiswa/diagnostic');
                  },
                  child: const Text('Lanjut ke Diagnostik'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}