import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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

      // Paint untuk Highlight Seleksi Tembok
      final Paint highlightPaint = Paint()
        ..color = Colors.blueAccent
            .withOpacity(0.4) // Biru transparan
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      bool isDrawingWall =
          controller.activeTool == PlanTool.wall &&
          controller.tempStart != null;
      bool showDims = controller.layerDims || isDrawingWall;

      for (var wall in controller.walls) {
        // --- PERBAIKAN BUG HIGHLIGHT DI SINI ---
        // Sebelumnya ada (!controller.isObjectSelected) yang membuat tembok gagal terdeteksi
        bool isSel =
            (controller.selectedId == wall.id) ||
            controller.multiSelectedIds.contains(wall.id);

        if (isSel) {
          // Gambar garis highlight tebal di bawah tembok asli
          highlightPaint.strokeWidth = wall.thickness + 12.0;
          canvas.drawLine(wall.start, wall.end, highlightPaint);
        }

        wallPaint.color = wall.color;
        wallPaint.strokeWidth = wall.thickness;

        // Gambar tembok asli
        canvas.drawLine(wall.start, wall.end, wallPaint);

        if (showDims) {
          _drawWallLabel(canvas, wall);
        }
      }

      // Preview saat menggambar tembok
      if (isDrawingWall &&
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
      }
    }

    // 3. Portals (Pintu/Jendela)
    // Digambar di atas layer tembok agar menutupi
    if (controller.layerWalls) {
      for (var portal in controller.portals) {
        bool isSel =
            (controller.selectedId == portal.id) ||
            controller.multiSelectedIds.contains(portal.id);
        _drawPortal(canvas, portal, isSel);
      }
    }

    // 4. Shapes, Objects & GROUPS (Layer Atas)
    if (controller.layerObjects) {
      // Groups
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

      // Shape Preview
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
            color: controller.activeColor,
            isFilled: controller.shapeFilled,
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

    // 5. Labels
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

  void _drawPortal(Canvas canvas, PlanPortal portal, bool isSelected) {
    canvas.save();
    canvas.translate(portal.position.dx, portal.position.dy);
    canvas.rotate(portal.rotation);

    final double w = portal.width;
    final double h = 6.0;

    Paint strokePaint = Paint()
      ..color = isSelected ? Colors.blue : portal.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Paint maskPaint = Paint()
      ..color = controller.canvasColor
      ..style = PaintingStyle.fill;

    if (isSelected) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w + 10, height: w + 10),
        Paint()..color = Colors.blueAccent.withOpacity(0.2),
      );
    }

    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w, height: h + 2),
      maskPaint,
    );

    if (portal.type == PlanPortalType.window) {
      Rect rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      canvas.drawRect(rect, strokePaint);
      canvas.drawLine(
        Offset(-w / 2, 0),
        Offset(w / 2, 0),
        strokePaint..strokeWidth = 1.0,
      );
    } else if (portal.type == PlanPortalType.door) {
      canvas.drawRect(
        Rect.fromLTWH(-w / 2, -h / 2, 4, h),
        Paint()..color = portal.color,
      );
      canvas.drawRect(
        Rect.fromLTWH(w / 2 - 4, -h / 2, 4, h),
        Paint()..color = portal.color,
      );

      Paint doorPaint = Paint()
        ..color = isSelected ? Colors.blue : portal.color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(-w / 2, -h / 2), Offset(-w / 2, -w), doorPaint);

      Paint arcPaint = Paint()
        ..color = (isSelected ? Colors.blue : portal.color).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(-w / 2, -h / 2), radius: w),
        -math.pi / 2,
        math.pi / 2,
        false,
        arcPaint,
      );
    }

    canvas.restore();
  }

  void _drawGroup(Canvas canvas, PlanGroup group, bool isSelected) {
    canvas.save();
    canvas.translate(group.position.dx, group.position.dy);
    canvas.rotate(group.rotation);

    if (isSelected) {
      final bounds = group.getBounds().inflate(10.0);
      canvas.drawRect(
        bounds,
        Paint()..color = Colors.blueAccent.withOpacity(0.2),
      );
      canvas.drawRect(
        bounds,
        Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

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
    for (double x = 0; x <= size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    for (double y = 0; y <= size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
  }

  void _drawShape(Canvas canvas, PlanShape shape, bool isSelected) {
    canvas.save();
    final center = shape.rect.center;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(shape.rotation);
    canvas.translate(-center.dx, -center.dy);

    final Paint fillPaint = Paint()
      ..color = isSelected
          ? Colors.blue.withOpacity(0.5)
          : shape.color.withOpacity(
              shape.isFilled
                  ? (shape.color.opacity == 1.0 ? 1.0 : shape.color.opacity)
                  : 0.0,
            )
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = isSelected ? Colors.blue : shape.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (shape.type == PlanShapeType.rectangle) {
      canvas.drawRect(shape.rect, fillPaint);
      canvas.drawRect(shape.rect, borderPaint);
    } else if (shape.type == PlanShapeType.circle) {
      canvas.drawOval(shape.rect, fillPaint);
      canvas.drawOval(shape.rect, borderPaint);
    } else if (shape.type == PlanShapeType.triangle) {
      final path = Path();
      path.moveTo(shape.rect.center.dx, shape.rect.top);
      path.lineTo(shape.rect.right, shape.rect.bottom);
      path.lineTo(shape.rect.left, shape.rect.bottom);
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    } else if (shape.type == PlanShapeType.hexagon) {
      final path = Path();
      final width = shape.rect.width;
      final height = shape.rect.height;
      final centerX = shape.rect.center.dx;
      final centerY = shape.rect.center.dy;
      for (int i = 0; i < 6; i++) {
        double angle = (60 * i - 30) * (math.pi / 180);
        double x = centerX + width / 2 * math.cos(angle);
        double y = centerY + height / 2 * math.sin(angle);
        if (i == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    } else if (shape.type == PlanShapeType.star) {
      _drawStar(canvas, shape.rect, fillPaint, borderPaint);
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
