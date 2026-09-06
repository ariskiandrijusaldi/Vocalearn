import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/student_profile_provider.dart';

/// ==========================================================
/// TRACK MAHASISWA — Langkah 3: Form Profil Mahasiswa
/// ==========================================================
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _daftarProdi = [
    'Manajemen Informatika',
    'Teknik Komputer',
    'Teknik Jaringan',
    'Teknologi Rekayasa Perangkat Lunak'
  ];

  static const _daftarMataKuliah = [
    'Praktik Jaringan Komputer',
    'Praktik Pemrograman Web',
    'Praktik Mobile'
  ];

  String? _selectedProdi;
  String? _selectedMataKuliah;

  @override
  Widget build(BuildContext context) {
    final isFormValid = _selectedProdi != null && _selectedMataKuliah != null;
    final user = ref.watch(authProvider).user;
    final kelasName = user?.kelasName;

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

                // --- Info Kelas ---
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kelasName != null
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.class_,
                        color: kelasName != null
                            ? const Color(0xFF2E7D32)
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kelas',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kelasName ?? 'Belum ada kelas',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kelasName != null
                                    ? const Color(0xFF1B5E20)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
