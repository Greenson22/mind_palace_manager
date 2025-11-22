// lib/features/plan_architect/presentation/plan_painter.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../logic/plan_controller.dart';
import '../data/plan_models.dart';

class PlanPainter extends CustomPainter {
  final PlanController controller;

  PlanPainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid
    _drawGrid(canvas, size);
    if (controller.enableSnap) _drawSnapPoints(canvas, size);

    // 2. Custom Paths (Gambar Bebas)
    final Paint pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var path in controller.paths) {
      bool isSel = (controller.selectedId == path.id);
      pathPaint.color = isSel ? Colors.blue : path.color;
      pathPaint.strokeWidth = isSel ? path.strokeWidth + 2.0 : path.strokeWidth;

      if (path.points.length > 1) {
        Path p = Path();
        p.moveTo(path.points.first.dx, path.points.first.dy);
        for (int i = 1; i < path.points.length; i++) {
          p.lineTo(path.points[i].dx, path.points[i].dy);
        }
        canvas.drawPath(p, pathPaint);
      } else if (path.points.isNotEmpty) {
        canvas.drawPoints(PointMode.points, path.points, pathPaint);
      }
    }

    // Preview Freehand
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

    // 3. Tembok
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
      _drawWallLabel(canvas, wall);
    }

    // Preview Tembok
    if (controller.activeTool == PlanTool.wall &&
        controller.tempStart != null &&
        controller.tempEnd != null) {
      Paint previewPaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 6.0;
      canvas.drawLine(controller.tempStart!, controller.tempEnd!, previewPaint);
      _drawWallLabel(
        canvas,
        Wall(
          id: 'temp',
          start: controller.tempStart!,
          end: controller.tempEnd!,
        ),
      );

      // Visualisasi Magnet (Lingkaran kecil di ujung jika menempel)
      canvas.drawCircle(
        controller.tempStart!,
        4,
        Paint()..color = Colors.redAccent,
      );
      canvas.drawCircle(
        controller.tempEnd!,
        4,
        Paint()..color = Colors.redAccent,
      );
    }

    // 4. Objek Icon
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
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawSnapPoints(Canvas canvas, Size size) {
    Paint snapPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    double step = controller.gridSize;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, snapPaint);
      }
    }
  }

  void _drawWallLabel(Canvas canvas, Wall wall) {
    final center = (wall.start + wall.end) / 2;
    final lengthPx = (wall.start - wall.end).distance;
    if (lengthPx < 20) return;
    final lengthM = (lengthPx / 40).toStringAsFixed(1);
    final textSpan = TextSpan(
      text: "${lengthM}m",
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final rect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 4,
      height: textPainter.height + 2,
    );
    canvas.drawRect(rect, Paint()..color = Colors.white.withOpacity(0.7));
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant PlanPainter oldDelegate) => true;
}
