// lib/features/pixel_studio/presentation/canvas_painter.dart
import 'package:flutter/material.dart';
import '../logic/drawing_controller.dart';

class PixelCanvasPainter extends CustomPainter {
  final DrawingController controller;
  final double zoomScale; // Untuk grid dinamis

  PixelCanvasPainter({required this.controller, required this.zoomScale})
    : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar Background Kanvas (Putih/Transparan Checkerboard)
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Ukuran 1 piksel virtual
    final double pixelSize = size.width / controller.gridSize;
    final Paint pixelPaint = Paint()..style = PaintingStyle.fill;

    // 2. Gambar Piksel Aktif
    controller.pixels.forEach((key, color) {
      final coords = key.split('_');
      final int x = int.parse(coords[0]);
      final int y = int.parse(coords[1]);

      pixelPaint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(
          x * pixelSize,
          y * pixelSize,
          pixelSize +
              0.5, // +0.5 untuk menghindari garis celah tipis (anti-aliasing artifact)
          pixelSize + 0.5,
        ),
        pixelPaint,
      );
    });

    // 3. Grid Dinamis (Hanya muncul jika di-zoom in > 2.0)
    if (zoomScale > 2.0) {
      final Paint gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 0.5;

      for (int i = 0; i <= controller.gridSize; i++) {
        double pos = i * pixelSize;
        // Garis Vertikal
        canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
        // Garis Horizontal
        canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelCanvasPainter oldDelegate) {
    return true; // Selalu repaint saat controller berubah
  }
}
