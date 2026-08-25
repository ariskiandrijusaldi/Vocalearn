import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/api_client.dart';
import '../../data/providers/auth_provider.dart';

// ============================================================
// THEME TOKENS — sesuai desain (cream + teal + gold)
// ============================================================
class _Vc {
  static const cream = Color(0xFFFBF7EA);
  static const teal = Color(0xFF163B39);
  static const tealDark = Color(0xFF102B29);
  static const gold = Color(0xFFC9A961);
  static const goldLight = Color(0xFFE7D9AE);
  static const fieldFill = Color(0xFFFBF7EA);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();

  /// null = pilihan role, string = login/register sebagai role itu
  String? _selectedRole;

  /// false = login, true = register
  bool _isRegistering = false;

  /// toggle lihat/sembunyikan password
  bool _obscurePassword = true;

  /// Daftar kelas untuk form registrasi
  List<dynamic> _kelasList = [];
  int? _selectedKelasId;

  // ============================================================
  // SPLASH ANIMATION
  // ============================================================
  late final AnimationController _splashController;
  late final Animation<double> _splashIconAnim;
  late final Animation<double> _splashTextAnim;

  bool _splashDone = false;

  // ============================================================
  // INTRO ANIMATION
  // ============================================================
  late final AnimationController _introController;
  late final Animation<double> _logoAnim;
  late final Animation<double> _panelAnim;
  late final Animation<double> _contentAnim;

  bool _introDone = false;

  @override
  void initState() {
    super.initState();

    // --- Splash: logo sendiri -> wordmark muncul ---
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _splashIconAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOutBack),
    );
    _splashTextAnim = CurvedAnimation(
      parent: _splashController,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );
    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _splashDone = true);
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) _introController.forward();
        });
      }
    });

    // --- Intro: logo naik ke header, panel slide up, konten fade-in ---
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _logoAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _panelAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.18, 0.75, curve: Curves.easeOutCubic),
    );
    _contentAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.62, 1.0, curve: Curves.easeOut),
    );
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _introDone = true);
      }
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _splashController.forward();
    });

    _loadKelasList();
  }

  Future<void> _loadKelasList() async {
    try {
      final resp = await ApiClient.instance.dio.get('/kelas/public');
      if (mounted) {
        setState(() => _kelasList = resp.data as List<dynamic>);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Vc.cream,
      body: !_splashDone
          ? _buildSplashLayout()
          : (_introDone ? _buildMainLayout() : _buildIntroLayout()),
    );
  }

  // ------------------------------------------------------------
  // Layout splash
  // ------------------------------------------------------------
  Widget _buildSplashLayout() {
    return AnimatedBuilder(
      animation: _splashController,
      builder: (context, _) {
        final iconT = _splashIconAnim.value.clamp(0.0, 1.0);
        final textT = _splashTextAnim.value.clamp(0.0, 1.0);

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: iconT,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * iconT,
                  child: Image.asset(
                    'assets/images/logo_vocalearn.jpg',
                    width: 84,
                    height: 84,
                  ),
                ),
              ),
              if (textT > 0) SizedBox(width: 10 * textT),
              if (textT > 0)
                Opacity(
                  opacity: textT,
                  child: Transform.translate(
                    offset: Offset(-14 * (1 - textT), 0),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _Vc.teal,
                        ),
                        children: [
                          TextSpan(text: 'Voca'),
                          TextSpan(
                            text: 'learn',
                            style: TextStyle(color: _Vc.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Layout normal (interaktif)
  // ------------------------------------------------------------
  Widget _buildMainLayout() {
    final authState = ref.watch(authProvider);

    // BILA REGISTER: Menggunakan Column + Expanded agar Panel Teal full mengisi layar bawah
    // (TIDAK DIUBAH)
    if (_isRegistering) {
      return Column(
        children: [
          Container(
            color: _Vc.cream,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 100,
                child: _buildHeader(compact: true),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _Vc.teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: _buildRegisterForm(authState),
              ),
            ),
          ),
        ],
      );
    }

    // BILA LOGIN: layout persis seperti versi awal (TIDAK DIUBAH)
    // BILA PILIH ROLE: panel teal dibuat "ngepas" mengikuti tinggi konten
    // (menempel ke bawah layar) sehingga tidak ada ruang kosong
    // di bawah tombol Super Admin.
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: _selectedRole == null ? 170 : 160,
            child: Align(
              alignment: _selectedRole == null
                  ? Alignment.bottomCenter
                  : Alignment.center,
              child: _buildHeader(),
            ),
          ),
          Expanded(
            child: _selectedRole == null
                ? _buildRoleSelectionPanel(authState)
                : Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _Vc.teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildLoginForm(authState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Panel pemilihan role — tinggi mengikuti konten (ngepas),
  // ditempelkan ke bagian bawah layar agar tidak ada celah kosong
  // setelah tombol Super Admin, tanpa mengganggu logic apa pun.
  // ------------------------------------------------------------
  Widget _buildRoleSelectionPanel(AuthState authState) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: _Vc.teal,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: _buildRoleSelection(authState),
      ),
    );
  }

  // ------------------------------------------------------------
  // Layout intro (animasi awal)
  // ------------------------------------------------------------
  Widget _buildIntroLayout() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;

          final headerFinalHeight = 170.0;
          final logoBlockHeight = 170.0;

          return AnimatedBuilder(
            animation: _introController,
            builder: (context, _) {
              final logoT = _logoAnim.value;
              final panelT = _panelAnim.value;
              final contentT = _contentAnim.value;

              final logoStartTop = (h - logoBlockHeight) / 2;
              final logoEndTop = headerFinalHeight - logoBlockHeight;
              final logoTop =
                  logoStartTop + (logoEndTop - logoStartTop) * logoT;

              final panelStartTop = h;
              final panelEndTop = headerFinalHeight;
              final panelTop =
                  panelStartTop + (panelEndTop - panelStartTop) * panelT;

              return Stack(
                children: [
                  Positioned(
                    top: logoTop,
                    left: 0,
                    width: w,
                    height: headerFinalHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildHeader(),
                    ),
                  ),
                  Positioned(
                    top: panelTop,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: _Vc.teal,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(36),
                            topRight: Radius.circular(36),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          20,
                          24,
                          24 + MediaQuery.of(context).padding.bottom,
                        ),
                        child: Opacity(
                          opacity: contentT,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child:
                            _buildRoleSelection(ref.watch(authProvider)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader({bool compact = false}) {
    if (compact) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_vocalearn.jpg',
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _Vc.teal,
                ),
                children: [
                  TextSpan(text: 'Voca'),
                  TextSpan(text: 'learn', style: TextStyle(color: _Vc.gold)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_vocalearn.jpg',
              width: 94,
              height: 94,
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _Vc.teal,
                ),
                children: [
                  TextSpan(text: 'Voca'),
                  TextSpan(text: 'learn', style: TextStyle(color: _Vc.gold)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Adaptive Learning Engine untuk Praktik Vokasi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1 — Pilih Role
  // ============================================================
  Widget _buildRoleSelection(AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masuk sebagai',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        _RoleButton(
          icon: Icons.school,
          label: 'Mahasiswa',
          subtitle: 'Mahasiswa Politeknik Negeri Padang',
          onPressed: () => setState(() => _selectedRole = 'mahasiswa'),
        ),
        const SizedBox(height: 12),
        _RoleButton(
          icon: Icons.co_present,
          label: 'Dosen',
          subtitle: 'Isi email & password',
          onPressed: () => setState(() => _selectedRole = 'dosen'),
        ),
        const SizedBox(height: 12),
        _RoleButton(
          icon: Icons.admin_panel_settings,
          label: 'Super Admin',
          subtitle: 'Isi email & password',
          onPressed: () => setState(() => _selectedRole = 'admin'),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 2a — Form Login (TIDAK DIUBAH)
  // ============================================================
  Widget _buildLoginForm(AuthState authState) {
    final isDosen = _selectedRole == 'dosen';
    final isMahasiswa = _selectedRole == 'mahasiswa';
    final roleLabel =
    isMahasiswa ? 'Mahasiswa' : isDosen ? 'Dosen' : 'Super Admin';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _backToRoleSelection,
            ),
          ],
        ),
        const Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Login sebagai $roleLabel',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 28),

        const _FieldLabel('Email'),
        const SizedBox(height: 6),
        _VcTextField(
          controller: _emailController,
          hint: 'nama@email.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),

        const _FieldLabel('Password'),
        const SizedBox(height: 6),
        _VcTextField(
          controller: _passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.black45,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        if (authState.error != null) ...[
          const SizedBox(height: 10),
          Text(
            authState.error!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFFFB4B4)),
          ),
        ],

        const SizedBox(height: 26),
        _GoldButton(
          isLoading: authState.isLoading,
          label: 'SIGN IN',
          onPressed: authState.isLoading
              ? null
              : () async {
            await ref.read(authProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
            if (context.mounted) {
              final role = ref.read(authProvider).user?.role;
              if (role != null) context.go(role.homePath);
            }
          },
        ),

        const SizedBox(height: 14),
        const _SocialIconsRow(),

        if (isMahasiswa) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              GestureDetector(
                onTap: () => setState(() => _isRegistering = true),
                child: const Text(
                  'Sign up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _Vc.gold,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // STEP 2b — Form Register (TIDAK DIUBAH)
  // ============================================================
  Widget _buildRegisterForm(AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _isRegistering = false),
            ),
          ],
        ),
        const Text(
          'Buat Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Daftar Akun Mahasiswa',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 14),

        const _FieldLabel('Nama Lengkap'),
        const SizedBox(height: 4),
        _VcTextField(
          controller: _nameController,
          hint: 'Nama lengkap kamu',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 10),

        const _FieldLabel('Email'),
        const SizedBox(height: 4),
        _VcTextField(
          controller: _emailController,
          hint: 'nama@email.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),

        const _FieldLabel('Password'),
        const SizedBox(height: 4),
        _VcTextField(
          controller: _passwordController,
          hint: 'Min. 6 karakter',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.black45,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 10),

        const _FieldLabel('NIM'),
        const SizedBox(height: 4),
        _VcTextField(
          controller: _nimController,
          hint: 'NIM kamu',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 10),

        const _FieldLabel('Prodi'),
        const SizedBox(height: 4),
        _VcTextField(
          controller: _prodiController,
          hint: 'Program studi',
          icon: Icons.menu_book_outlined,
        ),
        const SizedBox(height: 10),

        const _FieldLabel('Kelas'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _Vc.fieldFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButton<int>(
            value: _selectedKelasId,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Pilih kelas', style: TextStyle(color: Colors.black38)),
            items: _kelasList
                .map<DropdownMenuItem<int>>((k) => DropdownMenuItem(
              value: k['id'] as int,
              child: Text(
                k['name'] ?? '',
                style: const TextStyle(color: Colors.black87),
              ),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedKelasId = v),
          ),
        ),

        if (authState.error != null) ...[
          const SizedBox(height: 10),
          Text(
            authState.error!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFFFB4B4)),
          ),
        ],

        const SizedBox(height: 26),
        _GoldButton(
          isLoading: authState.isLoading,
          label: 'DAFTAR',
          onPressed: authState.isLoading ? null : _register,
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sudah punya akun? ',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            GestureDetector(
              onTap: () => setState(() => _isRegistering = false),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _Vc.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ============================================================
  // LOGIC (TIDAK DIUBAH)
  // ============================================================
  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nim = _nimController.text.trim();
    final prodi = _prodiController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ref.read(authProvider.notifier).setError('Nama, email, dan password wajib diisi');
      return;
    }
    if (nim.isEmpty) {
      ref.read(authProvider.notifier).setError('NIM wajib diisi');
      return;
    }
    if (prodi.isEmpty) {
      ref.read(authProvider.notifier).setError('Prodi wajib diisi');
      return;
    }
    if (_selectedKelasId == null) {
      ref.read(authProvider.notifier).setError('Kelas wajib dipilih');
      return;
    }

    await ref.read(authProvider.notifier).register(
      email: email,
      password: password,
      fullName: name,
      nim: nim,
      prodi: prodi,
      kelasId: _selectedKelasId!,
    );

    if (context.mounted) {
      final state = ref.read(authProvider);
      if (state.error == null && state.isLoggedIn) {
        context.go('/mahasiswa');
      }
    }
  }

  void _backToRoleSelection() {
    setState(() {
      _selectedRole = null;
      _isRegistering = false;
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _nimController.clear();
      _prodiController.clear();
    });
    ref.read(authProvider.notifier).clearError();
  }

  @override
  void dispose() {
    _splashController.dispose();
    _introController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nimController.dispose();
    _prodiController.dispose();
    super.dispose();
  }
}

// ============================================================
// UI PARTS (TIDAK DIUBAH)
// ============================================================
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

class _VcTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _VcTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.black45, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _Vc.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoldButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _Vc.gold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _Vc.tealDark,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: _Vc.tealDark,
          ),
        ),
      ),
    );
  }
}

class _SocialIconsRow extends StatelessWidget {
  const _SocialIconsRow();

  @override
  Widget build(BuildContext context) {
    Widget circle(Widget child) => Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onPressed;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _Vc.gold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _Vc.gold.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _Vc.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
