/// Utilitas untuk memproses link YouTube dari materi modul.
library;

/// Mengambil ID video dari berbagai format link YouTube.
///
/// Mendukung:
/// - https://www.youtube.com/watch?v=VIDEO_ID
/// - https://youtu.be/VIDEO_ID
/// - https://www.youtube.com/shorts/VIDEO_ID
/// - https://www.youtube.com/embed/VIDEO_ID
/// - https://www.youtube.com/live/VIDEO_ID
/// - Link dengan parameter tambahan (?t=90s, &list=..., dll.)
///
/// Mengembalikan null jika URL bukan link YouTube yang valid.
String? extractYoutubeVideoId(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return null;

  final host = uri.host.toLowerCase().replaceAll('www.', '');
  final isYoutubeHost = host == 'youtube.com' ||
      host == 'm.youtube.com' ||
      host == 'youtu.be' ||
      host == 'youtube-nocookie.com';
  if (!isYoutubeHost) return null;

  // youtu.be/VIDEO_ID
  if (host == 'youtu.be') {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return _isValidId(id) ? id : null;
  }

  // youtube.com/watch?v=VIDEO_ID
  final v = uri.queryParameters['v'];
  if (v != null && _isValidId(v)) return v;

  // youtube.com/{shorts|embed|live}/VIDEO_ID
  const pathPrefixes = ['shorts', 'embed', 'live'];
  if (uri.pathSegments.length >= 2 &&
      pathPrefixes.contains(uri.pathSegments.first.toLowerCase())) {
    final id = uri.pathSegments[1];
    return _isValidId(id) ? id : null;
  }

  return null;
}

bool _isValidId(String id) => RegExp(r'^[A-Za-z0-9_-]{6,20}$').hasMatch(id);
