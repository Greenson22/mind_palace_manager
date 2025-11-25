import 'dart:io';
import 'package:flutter/material.dart';

class PlanViewInfoSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const PlanViewInfoSheet({super.key, required this.data});

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.1,
                maxScale: 5.0,
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String? refImage = data['refImage'];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (refImage != null && File(refImage).existsSync()) ...[
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, refImage!),
                  child: Hero(
                    tag: refImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(refImage),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "Ketuk gambar untuk memperbesar",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            data['title'] ?? 'Item',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(
              data['type'] ?? 'Object',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            backgroundColor: colorScheme.primaryContainer,
            side: BorderSide.none,
          ),
          const Divider(height: 24),
          Text(
            (data['desc'] != null && data['desc'].isNotEmpty)
                ? data['desc']
                : "Tidak ada deskripsi.",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
