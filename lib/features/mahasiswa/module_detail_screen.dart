import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/config/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/youtube.dart';
import '../../data/repositories/dosen_service.dart';
import '../../data/repositories/ai_service.dart';
import '../../data/providers/auth_provider.dart';
import 'pdf_viewer_screen.dart';
import 'quiz_screen.dart';

class ModuleDetailScreen extends ConsumerStatefulWidget {
  final String moduleId;
  const ModuleDetailScreen({super.key, required this.moduleId});

  @override
  ConsumerState<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends ConsumerState<ModuleDetailScreen> {
  Map<String, dynamic>? _module;
  bool _isLoading = true;
  YoutubePlayerController? _ytController;
  final _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _chatLoading = false;

  /// Mastery per modul (0..1) dari mesin rekomendasi; kosong jika gagal dimuat.
  Map<int, double> _masteryByModule = {};
  bool _recFailed = false;

  /// Rangkuman AI milik mahasiswa untuk modul ini. Hanya ada jika nilai
  /// kuis sebelumnya di bawah ambang penguasaan (dibuat saat kuis selesai).
  Map<String, dynamic>? _rangkuman;

  /// Selaras MASTERY_THRESHOLD di backend (app/ai/scheduler.py).
  static const double _kMasteryThreshold = 0.8;

  /// Modul yang sudah dikuasai tidak bisa mengerjakan kuis ulang.
  bool get _modulDikuasai {
    if (_recFailed || _module == null) return false;
    final id = int.tryParse(widget.moduleId);
    if (id == null) return false;
    return (_masteryByModule[id] ?? 0) >= _kMasteryThreshold;
  }

  @override
  void initState() {
    super.initState();
    _loadModule();
  }

  Future<void> _loadModule() async {
    setState(() => _isLoading = true);
    try {
      final modules = await DosenService().getModules(status: 'published');
      final found = modules.firstWhere(
        (m) => m['id'].toString() == widget.moduleId,
        orElse: () => null,
      );
      _initYoutubePlayer(found);

      // Muat status penguasaan (best-effort) untuk mengunci kuis modul
      // yang sudah dikuasai. Gagal memuat -> semua modul tetap terbuka.
      var mastery = <int, double>{};
      var failed = false;
      try {
        final studentId = ref.read(authProvider).user?.id ?? 0;
        final rec = await DosenService().getRecommendation(studentId);
        for (final c in (rec['competencies'] as List<dynamic>? ?? [])) {
          final mid = c['module_id'];
          if (mid != null) {
            mastery[(mid as num).toInt()] =
                ((c['mastery'] ?? 0) as num).toDouble();
          }
        }
      } catch (_) {
        failed = true;
      }

      // Rangkuman AI modul ini (best-effort) — muncul hanya jika sudah dibuat.
      Map<String, dynamic>? rangkuman;
      final mid = int.tryParse(widget.moduleId);
      if (mid != null) {
        try {
          rangkuman =
              await AiService().getSimplifiedMaterial(materialId: mid);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _module = found;
        _masteryByModule = mastery;
        _recFailed = failed;
        _rangkuman = rangkuman;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _initYoutubePlayer(Map<String, dynamic>? mod) {
    final videoId = extractYoutubeVideoId(mod?['youtube_url'] as String?);
    if (videoId == null) return;
    _ytController?.close();
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        interfaceLanguage: 'id',
      ),
    );
  }

  /// Membuka [url] di aplikasi eksternal (YouTube, browser, penampil PDF).
  ///
  /// Sengaja tidak memakai canLaunchUrl — di Android 11+ hasilnya selalu false
  /// tanpa deklarasi <queries>. Langsung launch dan tangkap error jika tidak
  /// ada handler yang cocok.
  Future<void> _bukaLinkEksternal(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link')),
        );
      }
    }
  }

  /// Membuka rangkuman sebagai PDF di penampil bawaan; dari sana bisa
  /// disimpan ke penyimpanan HP lewat tombol unduh.
  Future<void> _bukaRangkumanPdf() async {
    final token = await ApiClient.instance.token;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          url:
              '${AppConfig.baseUrl}/ai/simplified-material/${widget.moduleId}/pdf',
          title: 'Rangkuman - ${_module?['title'] ?? ''}',
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      ),
    );
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'text': text, 'isUser': true});
      _chatLoading = true;
      _chatController.clear();
    });

    try {
      final studentId = ref.read(authProvider).user?.id ?? 0;
      final response = await AiService().chatTutor(
        studentId: studentId,
        pesan: text,
        materialId: int.tryParse(widget.moduleId),
      );
      setState(() {
        _chatMessages.add({
          'text': response['pesan'] ?? 'Tidak ada jawaban.',
          'isUser': false,
        });
      });
    } catch (e) {
      String msg = 'Maaf, terjadi kesalahan. Coba lagi nanti.';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['detail']?.toString() ?? msg;
      }
      setState(() {
        _chatMessages.add({'text': msg, 'isUser': false});
      });
    } finally {
      setState(() => _chatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream2,
          elevation: 0,
          title: const Text('Memuat...', style: TextStyle(color: AppColors.dark)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_module == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream2,
          elevation: 0,
          title: const Text('Modul tidak ditemukan', style: TextStyle(color: AppColors.dark)),
        ),
        body: const Center(child: Text('Modul ini tidak tersedia.')),
      );
    }

    final title = _module!['title'] ?? '';
    final description = _module!['description'] ?? '';
    final content = _module!['content'] ?? '';
    final hasPdf = _module!['pdf_path'] != null && (_module!['pdf_path'] as String).isNotEmpty;
    final hasYoutube = _module!['youtube_url'] != null && (_module!['youtube_url'] as String).isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream2,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // YouTube video
          if (hasYoutube) ...[
            if (_ytController != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: _ytController!,
                  aspectRatio: 16 / 9,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                onPressed: () =>
                    _bukaLinkEksternal(_module!['youtube_url'] as String),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text(
                    'Buka di aplikasi YouTube',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ] else
              // Link YouTube tidak dapat dikenali — buka di browser/aplikasi eksternal.
              GestureDetector(
                onTap: () =>
                    _bukaLinkEksternal(_module!['youtube_url'] as String),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF303030),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill,
                          size: 48, color: Colors.white70),
                      Positioned(
                        bottom: 10,
                        left: 12,
                        right: 12,
                        child: Text(
                          _module!['youtube_url'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ] else ...[
            // No video placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF303030),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // PDF modul — dibuka di penampil bawaan aplikasi
          if (hasPdf)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      url:
                          '${AppConfig.baseUrl}/uploads/modules/${_module!['pdf_path']}',
                      title: title,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'File PDF',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _module!['pdf_path'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.download, color: Colors.red, size: 20),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Description
          Text(
            description.isNotEmpty ? description : 'Baca materi di bawah, lalu uji pemahamanmu lewat kuis.',
            style: const TextStyle(color: AppColors.body, fontSize: 16, height: 1.6),
          ),

          // Content body
          if (content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(color: AppColors.body, fontSize: 14, height: 1.6),
            ),
          ],

          // Rangkuman AI — hanya muncul jika nilai kuis sebelumnya rendah,
          // sehingga rangkuman sudah dibuatkan saat kuis tersebut selesai.
          if (_rangkuman != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.yellow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize_outlined, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rangkuman Mudah Dipahami',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nilai kuismu di modul ini belum mencapai ambang penguasaan. '
                    'Pelajari rangkuman berikut sebelum mencoba lagi.',
                    style: TextStyle(fontSize: 12, color: AppColors.body),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _rangkuman!['konten_sederhana'] ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.55),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _bukaRangkumanPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Lihat / Unduh PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Kerjakan kuis — terkunci jika modul sudah dikuasai (tidak bisa
          // kuis ulang); modul belum dikuasai boleh diulang sampai lulus.
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _modulDikuasai
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            materialId: _module!['id'] as int,
                            materialTitle: title,
                          ),
                        ),
                      );
                      // Status penguasaan bisa berubah setelah kuis selesai.
                      _loadModule();
                    },
              icon: Icon(
                _modulDikuasai ? Icons.verified_outlined : Icons.quiz_outlined,
              ),
              label: Text(
                _modulDikuasai ? 'MODUL DIKUASAI' : 'KERJAKAN KUIS',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .7,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.green.withAlpha(128),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          if (_modulDikuasai) ...[
            const SizedBox(height: 8),
            const Text(
              'Kuis modul ini sudah dikuasai dan tidak dapat dikerjakan ulang. Lanjutkan ke modul berikutnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.body, fontSize: 12),
            ),
          ],

          const SizedBox(height: 30),

          // Chat assistant
          const Text(
            'Tanya Asisten Belajar',
            style: TextStyle(
              color: Color(0xFF1B1C1C),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          if (_chatMessages.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (final msg in _chatMessages) ...[
                    Align(
                      alignment: msg['isUser'] == true
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: _ChatBubble(
                        text: msg['text'] as String,
                        isUser: msg['isUser'] as bool,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Tanya seputar materi modul ini...',
                    filled: true,
                    fillColor: const Color(0xFFEFEDED),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.filled(
                  onPressed: _chatLoading ? null : _sendChat,
                  icon: _chatLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: AppColors.green),
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
    _ytController?.close();
    _chatController.dispose();
    super.dispose();
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 304),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.green : const Color(0xFFEFEDED),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 16 : 2),
          topRight: Radius.circular(isUser ? 2 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isUser ? const Color(0xFFFFF9E5) : const Color(0xFF1B1C1C),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}
