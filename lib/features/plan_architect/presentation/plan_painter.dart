// lib/features/plan_architect/presentation/plan_painter.dart
import 'package:flutter/material.dart';
import '../logic/plan_controller.dart';

class PlanPainter extends CustomPainter {
  final PlanController controller;

  PlanPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar Grid (Opsional, biar seperti arsitek)
    _drawGrid(canvas, size);

    final Paint wallPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.square;

    final Paint selectedPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.square;

    // 2. Gambar Tembok
    for (var wall in controller.walls) {
      bool isSel =
          (!controller.isObjectSelected && controller.selectedId == wall.id);
      canvas.drawLine(wall.start, wall.end, isSel ? selectedPaint : wallPaint);
    }

    // 3. Gambar Tembok yang sedang ditarik (Preview)
    if (controller.tempStart != null && controller.tempEnd != null) {
      Paint previewPaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 6.0;
      canvas.drawLine(controller.tempStart!, controller.tempEnd!, previewPaint);
    }

    // 4. Gambar Objek (Interior)
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var obj in controller.objects) {
      bool isSel =
          (controller.isObjectSelected && controller.selectedId == obj.id);

      // Gambar highlight jika selected
      if (isSel) {
        canvas.drawCircle(
          obj.position,
          24,
          Paint()..color = Colors.blue.withOpacity(0.3),
        );
      }

      // Gambar Icon
      final icon = IconData(obj.iconCodePoint, fontFamily: 'MaterialIcons');
      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 32,
          fontFamily: icon.fontFamily,
          color: isSel ? Colors.blue : Colors.black87,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, obj.position - Offset(16, 16)); // Center icon
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PlanPainter oldDelegate) => true;
}
