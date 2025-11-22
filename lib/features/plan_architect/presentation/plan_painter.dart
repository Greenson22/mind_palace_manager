// lib/features/plan_architect/presentation/plan_painter.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Untuk PointMode
import '../logic/plan_controller.dart';

class PlanPainter extends CustomPainter {
  final PlanController controller;

  PlanPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    // --- 1. GAMBAR PATHS (Custom Interior) ---
    final Paint pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var path in controller.paths) {
      pathPaint.color = path.color;
      pathPaint.strokeWidth = path.strokeWidth;

      if (path.points.length > 1) {
        // Gambar garis mulus
        Path p = Path();
        p.moveTo(path.points.first.dx, path.points.first.dy);
        for (int i = 1; i < path.points.length; i++) {
          p.lineTo(path.points[i].dx, path.points[i].dy);
        }
        canvas.drawPath(p, pathPaint);
      } else if (path.points.isNotEmpty) {
        // Gambar titik jika hanya 1 point
        canvas.drawPoints(PointMode.points, path.points, pathPaint);
      }
    }

    // Gambar path yang sedang ditarik (Preview Freehand)
    if (controller.activeTool == PlanTool.freehand &&
        controller.currentPathPoints.isNotEmpty) {
      pathPaint.color = Colors.brown.withOpacity(0.7);
      pathPaint.strokeWidth = 2.0;
      Path p = Path();
      p.moveTo(
        controller.currentPathPoints.first.dx,
        controller.currentPathPoints.first.dy,
      );
      for (int i = 1; i < controller.currentPathPoints.length; i++) {
        p.lineTo(
          controller.currentPathPoints[i].dx,
          controller.currentPathPoints[i].dy,
        );
      }
      canvas.drawPath(p, pathPaint);
    }

    // --- 2. GAMBAR TEMBOK ---
    final Paint wallPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.square;

    final Paint selectedPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.square;

    for (var wall in controller.walls) {
      bool isSel =
          (!controller.isObjectSelected && controller.selectedId == wall.id);
      canvas.drawLine(wall.start, wall.end, isSel ? selectedPaint : wallPaint);
    }

    // Preview Tembok
    if (controller.activeTool == PlanTool.wall &&
        controller.tempStart != null &&
        controller.tempEnd != null) {
      Paint previewPaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 6.0;
      canvas.drawLine(controller.tempStart!, controller.tempEnd!, previewPaint);
    }

    // --- 3. GAMBAR OBJEK ---
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var obj in controller.objects) {
      bool isSel =
          (controller.isObjectSelected && controller.selectedId == obj.id);

      if (isSel) {
        canvas.drawCircle(
          obj.position,
          24,
          Paint()..color = Colors.blue.withOpacity(0.3),
        );
      }

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
      textPainter.paint(canvas, obj.position - Offset(16, 16));
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
