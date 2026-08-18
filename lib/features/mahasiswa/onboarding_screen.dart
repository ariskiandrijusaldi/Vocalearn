import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ==========================================================
/// TRACK MAHASISWA — Langkah 2: Halaman Onboarding
/// ==========================================================
/// Terhubung ke to-do list §3 & Mini-PRD Fitur 1.
/// Acceptance criteria (dari Mini-PRD): 2-3 slide penjelasan singkat,
/// tombol "Lewati" dan "Mulai" — tidak perlu animasi rumit.
///
/// TODO selanjutnya (Alya):
///   [ ] Setelah tombol "Mulai" ditekan, arahkan ke form profil mahasiswa
///       (ganti context.go('/mahasiswa') di bawah begitu ProfileScreen jadi)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.psychology_outlined,
      title: 'Belajar Praktik yang Personal',
      description:
      'VocaLearn menyesuaikan modul praktik dengan kemampuanmu, '
          'bukan menyamaratakan semua mahasiswa.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_graph_outlined,
      title: 'Rekomendasi Otomatis dari AI',
      description:
      'Sistem memantau progresmu dan merekomendasikan modul '
          'berikutnya yang paling kamu butuhkan.',
    ),
    _OnboardingSlide(
      icon: Icons.assignment_turned_in_outlined,
      title: 'Mulai dari Diagnostik Singkat',
      description:
      'Isi asesmen awal dulu supaya VocaLearn tahu titik mulai '
          'kompetensimu sebelum masuk ke modul praktik.',
    ),
  ];

  void _finishOnboarding() {
    // Setelah profile_screen.dart dibuat (langkah 3), arahkan ke sana.
    // TODO (Alya): ganti lagi ke '/mahasiswa/diagnostic' setelah
    // DiagnosticScreen (langkah 4) selesai dibuat.
    context.go('/mahasiswa/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text('Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 96,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indikator titik halaman
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final isLastPage = _currentPage == _slides.length - 1;
                    if (isLastPage) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Mulai' : 'Lanjut',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}