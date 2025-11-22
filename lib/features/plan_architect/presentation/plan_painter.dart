// lib/features/plan_architect/presentation/plan_painter.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../logic/plan_controller.dart';
import '../data/plan_models.dart';

class PlanPainter extends CustomPainter {
  final PlanController controller;
  PlanPainter({required this.controller}) : super(repaint: controller);

  // Helper untuk menentukan warna teks agar kontras dengan background canvas
  Color get _contrastColor {
    // Hitung kecerahan warna background (0.0 - 1.0)
    final double luminance = controller.canvasColor.computeLuminance();
    // Jika background terang (> 0.5), teks hitam. Jika gelap, teks putih.
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = controller.canvasColor,
    );

    // 1. Grid
    if (controller.showGrid) {
      _drawGrid(canvas, size);
    }

    // Snap Points
    if (!controller.isViewMode && controller.enableSnap) {
      // _drawSnapPoints(canvas, size); // Dimatikan untuk performa
    }

    // 2. Shapes & Objects
    if (controller.layerObjects) {
      for (var shape in controller.shapes) {
        _drawShape(canvas, shape, controller.selectedId == shape.id);
      }
      if (controller.activeTool == PlanTool.shape &&
          controller.tempStart != null &&
          controller.tempEnd != null) {
        final previewRect = Rect.fromPoints(
          controller.tempStart!,
          controller.tempEnd!,
        );
        _drawShape(
          canvas,
          PlanShape(
            id: 'temp',
            rect: previewRect,
            type: controller.selectedShapeType,
            color: controller.activeColor.withOpacity(0.5),
          ),
          false,
        );
      }

      TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
      for (var obj in controller.objects) {
        bool isSel = (controller.selectedId == obj.id);
        canvas.save();
        canvas.translate(obj.position.dx, obj.position.dy);
        canvas.rotate(obj.rotation);
        if (isSel)
          canvas.drawCircle(
            Offset.zero,
            (obj.size / 2) + 8, // Seleksi menyesuaikan ukuran
            Paint()..color = Colors.blue.withOpacity(0.3),
          );
        final icon = IconData(obj.iconCodePoint, fontFamily: 'MaterialIcons');
        tp.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: obj.size, // MENGGUNAKAN UKURAN DINAMIS
            fontFamily: icon.fontFamily,
            color: isSel ? Colors.blue : obj.color,
          ),
        );
        tp.layout();
        // Center icon
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }

      final Paint pathPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var path in controller.paths) {
        bool isSel = (controller.selectedId == path.id);
        pathPaint.color = isSel ? Colors.blue : path.color;
        pathPaint.strokeWidth = isSel
            ? path.strokeWidth + 2.0
            : path.strokeWidth;
        if (path.points.length > 1) {
          Path p = Path();
          p.moveTo(path.points.first.dx, path.points.first.dy);
          for (int i = 1; i < path.points.length; i++)
            p.lineTo(path.points[i].dx, path.points[i].dy);
          canvas.drawPath(p, pathPaint);
        } else if (path.points.isNotEmpty) {
          canvas.drawPoints(PointMode.points, path.points, pathPaint);
        }
      }
      if (controller.activeTool == PlanTool.freehand &&
          controller.currentPathPoints.isNotEmpty) {
        pathPaint.color = controller.activeColor.withOpacity(0.7);
        pathPaint.strokeWidth = controller.activeStrokeWidth;
        Path p = Path();
        p.moveTo(
          controller.currentPathPoints.first.dx,
          controller.currentPathPoints.first.dy,
        );
        for (int i = 1; i < controller.currentPathPoints.length; i++)
          p.lineTo(
            controller.currentPathPoints[i].dx,
            controller.currentPathPoints[i].dy,
          );
        canvas.drawPath(p, pathPaint);
      }
    }

    // 3. Labels
    if (controller.layerLabels) {
      TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
      for (var label in controller.labels) {
        bool isSel = (controller.selectedId == label.id);
        tp.text = TextSpan(
          text: label.text,
          style: TextStyle(
            color: isSel
                ? Colors.blue
                : label.color, // Warna label mengikuti setting user
            fontSize: label.fontSize,
            fontWeight: FontWeight.bold,
            // Beri shadow agar terbaca di segala medan
            shadows: [
              Shadow(
                blurRadius: 2,
                color: _contrastColor == Colors.white
                    ? Colors.black
                    : Colors.white,
              ),
            ],
          ),
        );
        tp.layout();
        tp.paint(canvas, label.position - Offset(tp.width / 2, tp.height / 2));
        if (isSel) {
          canvas.drawRect(
            Rect.fromCenter(
              center: label.position,
              width: tp.width + 10,
              height: tp.height + 10,
            ),
            Paint()
              ..color = Colors.blue.withOpacity(0.1)
              ..style = PaintingStyle.fill,
          );
          canvas.drawRect(
            Rect.fromCenter(
              center: label.position,
              width: tp.width + 10,
              height: tp.height + 10,
            ),
            Paint()
              ..color = Colors.blue
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }
    }

    // 4. Walls
    if (controller.layerWalls) {
      final Paint wallPaint = Paint()..strokeCap = StrokeCap.square;
      final Paint selectedPaint = Paint()
        ..color = Colors.blueAccent
        ..strokeCap = StrokeCap.square;
      for (var wall in controller.walls) {
        bool isSel =
            (!controller.isObjectSelected && controller.selectedId == wall.id);
        wallPaint.color = wall.color;
        wallPaint.strokeWidth = wall.thickness;
        selectedPaint.strokeWidth = wall.thickness + 2.0;
        canvas.drawLine(
          wall.start,
          wall.end,
          isSel ? selectedPaint : wallPaint,
        );

        if (controller.layerDims) {
          _drawWallLabel(canvas, wall);
        }
      }
      if (controller.activeTool == PlanTool.wall &&
          controller.tempStart != null &&
          controller.tempEnd != null) {
        Paint previewPaint = Paint()
          ..color = controller.activeColor.withOpacity(0.5)
          ..strokeWidth = controller.activeStrokeWidth;
        canvas.drawLine(
          controller.tempStart!,
          controller.tempEnd!,
          previewPaint,
        );
        if (controller.layerDims)
          _drawWallLabel(
            canvas,
            Wall(
              id: 'temp',
              start: controller.tempStart!,
              end: controller.tempEnd!,
            ),
          );
        canvas.drawCircle(
          controller.tempStart!,
          2, // Titik ujung diperkecil
          Paint()..color = Colors.redAccent,
        );
        canvas.drawCircle(
          controller.tempEnd!,
          2,
          Paint()..color = Colors.redAccent,
        );
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    double step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawSnapPoints(Canvas canvas, Size size) {
    // Disabled for performance
  }

  void _drawShape(Canvas canvas, PlanShape shape, bool isSelected) {
    canvas.save();
    final center = shape.rect.center;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(shape.rotation);
    canvas.translate(-center.dx, -center.dy);
    final Paint paint = Paint()
      ..color = isSelected
          ? Colors.blue.withOpacity(0.5)
          : shape.color.withOpacity(shape.isFilled ? 0.5 : 0.0)
      ..style = PaintingStyle.fill;
    final Paint border = Paint()
      ..color = isSelected ? Colors.blue : shape.color
      ..strokeWidth =
          2 // Border shape diperkecil
      ..style = PaintingStyle.stroke;
    if (shape.type == PlanShapeType.rectangle) {
      canvas.drawRect(shape.rect, paint);
      canvas.drawRect(shape.rect, border);
    } else if (shape.type == PlanShapeType.circle) {
      canvas.drawOval(shape.rect, paint);
      canvas.drawOval(shape.rect, border);
    } else if (shape.type == PlanShapeType.star) {
      _drawStar(canvas, shape.rect, paint, border);
    }
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Rect rect, Paint fill, Paint border) {
    final center = rect.center;
    final radius = math.min(rect.width, rect.height) / 2;
    final innerRadius = radius / 2.5;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      double angle = (i * 36) * (math.pi / 180) - (math.pi / 2);
      double r = (i % 2 == 0) ? radius : innerRadius;
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  void _drawWallLabel(Canvas canvas, Wall wall) {
    final center = (wall.start + wall.end) / 2;
    final lengthPx = (wall.start - wall.end).distance;
    if (lengthPx < 20) return;
    final lengthM = (lengthPx / 40).toStringAsFixed(1);

    // Menggunakan warna kontras
    final textSpan = TextSpan(
      text: "${lengthM}m",
      style: TextStyle(
        color: _contrastColor.withOpacity(0.7), // Warna adaptif
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

    // Background label menyesuaikan agar teks terbaca
    canvas.drawRect(
      rect,
      Paint()..color = controller.canvasColor.withOpacity(0.7),
    );
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant PlanPainter oldDelegate) => true;
}
