import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class MaterialDetailScreen extends StatelessWidget {
  final Map<String, dynamic> module;
  const MaterialDetailScreen({super.key, required this.module});

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'review':
        return Colors.blue;
      case 'published':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'review':
        return 'Dalam Review';
      case 'published':
        return 'Diterbitkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = module['status'] as String? ?? 'draft';
    final title = module['title'] ?? '';
    final description = module['description'] ?? 'Tanpa deskripsi';
    final content = module['content'] ?? '';
    final difficulty = module['difficulty'] ?? 1;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                color: _statusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),

          const SizedBox(height: 10),

          // Description
          Text(description, style: const TextStyle(fontSize: 15)),

          const SizedBox(height: 16),

          // Difficulty
          Row(
            children: [
              const Text('Kesulitan: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...List.generate(5, (i) {
                return Icon(
                  i < difficulty ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ],
          ),

          const SizedBox(height: 20),

          // YouTube video
          if (module['youtube_url'] != null &&
              (module['youtube_url'] as String).isNotEmpty) ...[
            const Text(
              'Video Pembelajaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(module['youtube_url']);
                if (await canLaunchUrl(url)) {
                  launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.play_circle_fill, size: 56, color: Colors.white70),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        module['youtube_url'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Content
          if (content.isNotEmpty) ...[
            const Text(
              'Konten Materi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content,
                style: const TextStyle(height: 1.6),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Review note
          if (module['review_note'] != null &&
              (module['review_note'] as String).isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sage.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.dark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catatan Review',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module['review_note'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
