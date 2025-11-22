// lib/features/pixel_studio/presentation/canvas_painter.dart
import 'package:flutter/material.dart';
import '../logic/drawing_controller.dart';

class PixelCanvasPainter extends CustomPainter {
  final DrawingController controller;
  final double zoomScale;

  PixelCanvasPainter({required this.controller, required this.zoomScale})
    : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final double pixelSize = size.width / controller.gridSize;
    final Paint pixelPaint = Paint()..style = PaintingStyle.fill;

    // 1. Gambar Background Checkerboard (Transparansi)
    _drawCheckerboard(canvas, size, pixelSize);

    // 2. Gambar Piksel Utama (Committed)
    controller.pixels.forEach((key, color) {
      _drawPixel(canvas, key, color, pixelSize, pixelPaint);
    });

    // 3. Gambar Piksel Preview (Sedang ditarik: Garis/Kotak/Lingkaran)
    controller.previewPixels.forEach((key, color) {
      // Preview sedikit transparan agar terlihat bedanya
      _drawPixel(canvas, key, color.withOpacity(0.6), pixelSize, pixelPaint);
    });

    // 4. Grid Dinamis (Zoom > 5.0)
    if (zoomScale > 5.0) {
      _drawGrid(canvas, size, pixelSize);
    }
  }

  void _drawPixel(
    Canvas canvas,
    String key,
    Color color,
    double pxSize,
    Paint paint,
  ) {
    final coords = key.split('_');
    final int x = int.parse(coords[0]);
    final int y = int.parse(coords[1]);

    paint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(
        x * pxSize,
        y * pxSize,
        pxSize + 0.5, // Fix gap antialiasing
        pxSize + 0.5,
      ),
      paint,
    );
  }

  void _drawCheckerboard(Canvas canvas, Size size, double pxSize) {
    final Paint light = Paint()..color = Colors.white;
    final Paint dark = Paint()..color = Colors.grey.shade200;

    // Gambar background dasar
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), light);

    // Gambar pola (opsional, dimatikan untuk performa jika perlu)
    // Untuk sekarang kita pakai putih polos agar bersih
  }

  void _drawGrid(Canvas canvas, Size size, double pxSize) {
    final Paint gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 0.5;

    for (int i = 0; i <= controller.gridSize; i++) {
      double pos = i * pxSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PixelCanvasPainter oldDelegate) => true;
}
