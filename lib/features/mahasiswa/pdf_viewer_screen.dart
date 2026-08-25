import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

/// Menampilkan file PDF modul di dalam aplikasi.
///
/// File diunduh ke direktori cache terlebih dahulu, lalu dirender
/// menggunakan penampil native (AndroidPdfViewer/PDFKit).
class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  /// Header opsional untuk unduhan yang butuh autentikasi (mis. rangkuman AI).
  final Map<String, String> headers;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
    this.headers = const {},
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  int _totalPages = 0;
  int _currentPage = 0;
  double _downloadProgress = 0;
  bool _isDownloading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _downloadAndOpen();
  }

  Future<void> _downloadAndOpen() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _downloadProgress = 0;
    });
    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'modul_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savePath = File('${dir.path}/$fileName');

      await Dio().download(
        widget.url,
        savePath.path,
        options: Options(headers: widget.headers),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _localPath = savePath.path;
        _isDownloading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _error = 'Gagal memuat PDF. Periksa koneksi ke server.';
      });
    }
  }

  Future<void> _bukaEksternal() async {
    final uri = Uri.parse(widget.url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// Menyimpan PDF yang sudah terunduh di cache ke penyimpanan HP.
  ///
  /// Memakai dialog sistem (SAF) agar user memilih lokasi, mis. folder
  /// Download — tidak butuh izin storage tambahan.
  Future<void> _simpanKePenyimpanan() async {
    final path = _localPath;
    if (path == null) return;
    try {
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      final nama = _namaFileAman('${widget.title}.pdf');
      final hasil = await FilePicker.platform.saveFile(
        fileName: nama,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (!mounted) return;
      if (hasil != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF tersimpan sebagai "$nama"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan PDF')),
      );
    }
  }

  String _namaFileAman(String nama) {
    final bersih = nama.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return bersih.isEmpty ? 'modul.pdf' : bersih;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream2,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.dark),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Unduh ke penyimpanan',
            icon: const Icon(Icons.download),
            onPressed:
                (_isDownloading || _localPath == null) ? null : _simpanKePenyimpanan,
          ),
          IconButton(
            tooltip: 'Buka di aplikasi lain',
            icon: const Icon(Icons.open_in_new_outlined),
            onPressed: _bukaEksternal,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isDownloading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
            const SizedBox(height: 16),
            Text(
              _downloadProgress > 0
                  ? 'Mengunduh... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                  : 'Menyiapkan dokumen...',
              style: const TextStyle(color: AppColors.body),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.body)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _downloadAndOpen,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return const Center(child: Text('Dokumen tidak tersedia.'));
    }

    return Stack(
      children: [
        PDFView(
          filePath: _localPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          fitPolicy: FitPolicy.WIDTH,
          onError: (_) {
            if (mounted) {
              setState(() => _error = 'Gagal menampilkan dokumen.');
            }
          },
          onPageError: (page, _) {
            if (mounted) {
              setState(
                  () => _error = 'Gagal menampilkan halaman ${(page ?? 0) + 1}.');
            }
          },
          onPageChanged: (page, total) {
            if (mounted) {
              setState(() {
                _currentPage = page ?? 0;
                _totalPages = total ?? 0;
              });
            }
          },
        ),
        if (_totalPages > 0)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
