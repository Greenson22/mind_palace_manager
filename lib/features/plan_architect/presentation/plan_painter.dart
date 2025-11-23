// lib/features/plan_architect/presentation/plan_painter.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // FIX: Tambahkan 'as ui'
import 'dart:math' as math;
import '../logic/plan_controller.dart';
import '../data/plan_models.dart';

class PlanPainter extends CustomPainter {
  final PlanController controller;
  PlanPainter({required this.controller}) : super(repaint: controller);

  Color get _contrastColor {
    final double luminance = controller.canvasColor.computeLuminance();
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

    // 2. Walls (Layer Bawah)
    if (controller.layerWalls) {
      final Paint wallPaint = Paint()..strokeCap = StrokeCap.square;
      final Paint selectedPaint = Paint()
        ..color = Colors.blueAccent
        ..strokeCap = StrokeCap.square;

      bool isDrawingWall =
          controller.activeTool == PlanTool.wall &&
          controller.tempStart != null;
      bool showDims = controller.layerDims || isDrawingWall;

      for (var wall in controller.walls) {
        bool isSel =
            (!controller.isObjectSelected &&
                controller.selectedId == wall.id) ||
            controller.multiSelectedIds.contains(wall.id);
        wallPaint.color = wall.color;
        wallPaint.strokeWidth = wall.thickness;
        selectedPaint.strokeWidth = wall.thickness + 2.0;
        canvas.drawLine(
          wall.start,
          wall.end,
          isSel ? selectedPaint : wallPaint,
        );

        if (showDims) {
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
        _drawWallLabel(
          canvas,
          Wall(
            id: 'temp',
            start: controller.tempStart!,
            end: controller.tempEnd!,
          ),
        );
      }
    }

    // 3. Shapes, Objects & GROUPS (Layer Atas)
    if (controller.layerObjects) {
      // --- GAMBAR GRUP ---
      for (var group in controller.groups) {
        bool isSel =
            (controller.selectedId == group.id) ||
            controller.multiSelectedIds.contains(group.id);
        _drawGroup(canvas, group, isSel);
      }

      // Shapes
      for (var shape in controller.shapes) {
        bool isSel =
            (controller.selectedId == shape.id) ||
            controller.multiSelectedIds.contains(shape.id);
        _drawShape(canvas, shape, isSel);
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

      // Objects
      TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
      for (var obj in controller.objects) {
        bool isSel =
            (controller.selectedId == obj.id) ||
            controller.multiSelectedIds.contains(obj.id);
        canvas.save();
        canvas.translate(obj.position.dx, obj.position.dy);
        canvas.rotate(obj.rotation);

        if (isSel) {
          double selectionRadius = (obj.size / 2) + 8;
          canvas.drawCircle(
            Offset.zero,
            selectionRadius,
            Paint()..color = Colors.blue.withOpacity(0.3),
          );
        }

        if (obj.cachedImage != null) {
          _drawImage(canvas, obj.cachedImage!, obj.size);
        } else {
          final icon = IconData(obj.iconCodePoint, fontFamily: 'MaterialIcons');
          tp.text = TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: obj.size,
              fontFamily: icon.fontFamily,
              color: isSel ? Colors.blue : obj.color,
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        }
        canvas.restore();
      }

      // Paths
      final Paint pathPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var path in controller.paths) {
        bool isSel =
            (controller.selectedId == path.id) ||
            controller.multiSelectedIds.contains(path.id);
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
          // FIX: Gunakan ui.PointMode karena dart:ui dialiaskan
          canvas.drawPoints(ui.PointMode.points, path.points, pathPaint);
        }
      }
      // Freehand Preview
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

    // 4. Labels
    if (controller.layerLabels) {
      TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
      for (var label in controller.labels) {
        bool isSel =
            (controller.selectedId == label.id) ||
            controller.multiSelectedIds.contains(label.id);
        tp.text = TextSpan(
          text: label.text,
          style: TextStyle(
            color: isSel ? Colors.blue : label.color,
            fontSize: label.fontSize,
            fontWeight: FontWeight.bold,
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
        }
      }
    }
  }

  // --- DRAW GROUP ---
  void _drawGroup(Canvas canvas, PlanGroup group, bool isSelected) {
    canvas.save();
    canvas.translate(group.position.dx, group.position.dy);
    canvas.rotate(group.rotation);

    // Visual Seleksi Grup
    if (isSelected) {
      canvas.drawCircle(
        Offset.zero,
        30,
        Paint()..color = Colors.orange.withOpacity(0.2),
      );
      canvas.drawCircle(
        Offset.zero,
        30,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Render isi grup
    for (var shp in group.shapes) _drawShape(canvas, shp, false);

    final Paint pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var path in group.paths) {
      pathPaint.color = path.color;
      pathPaint.strokeWidth = path.strokeWidth;
      if (path.points.length > 1) {
        Path p = Path();
        p.moveTo(path.points.first.dx, path.points.first.dy);
        for (int i = 1; i < path.points.length; i++)
          p.lineTo(path.points[i].dx, path.points[i].dy);
        canvas.drawPath(p, pathPaint);
      }
    }

    TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (var obj in group.objects) {
      canvas.save();
      canvas.translate(obj.position.dx, obj.position.dy);
      canvas.rotate(obj.rotation);
      if (obj.cachedImage != null) {
        _drawImage(canvas, obj.cachedImage!, obj.size);
      } else {
        final icon = IconData(obj.iconCodePoint, fontFamily: 'MaterialIcons');
        tp.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: obj.size,
            fontFamily: icon.fontFamily,
            color: obj.color,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      }
      canvas.restore();
    }

    for (var label in group.labels) {
      tp.text = TextSpan(
        text: label.text,
        style: TextStyle(
          color: label.color,
          fontSize: label.fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
      tp.layout();
      tp.paint(canvas, label.position - Offset(tp.width / 2, tp.height / 2));
    }

    canvas.restore();
  }

  // FIX: Gunakan ui.Image di sini
  void _drawImage(Canvas canvas, ui.Image img, double size) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    double drawWidth = size;
    double drawHeight = size;
    final double aspectRatio = img.width / img.height;
    if (aspectRatio > 1) {
      drawHeight = drawWidth / aspectRatio;
    } else {
      drawWidth = drawHeight * aspectRatio;
    }
    final dstRect = Rect.fromCenter(
      center: Offset.zero,
      width: drawWidth,
      height: drawHeight,
    );
    canvas.drawImageRect(img, srcRect, dstRect, Paint());
  }

  void _drawGrid(Canvas canvas, Size size) {
    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    double step = controller.gridSize;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
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
      ..strokeWidth = 2
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
    final textSpan = TextSpan(
      text: "${lengthM}m",
      style: TextStyle(
        color: _contrastColor.withOpacity(0.7),
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
