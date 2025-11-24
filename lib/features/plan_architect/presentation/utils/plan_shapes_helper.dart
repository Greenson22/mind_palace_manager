// lib/features/plan_architect/presentation/utils/plan_shapes_helper.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../logic/plan_enums.dart';

class PlanShapesHelper {
  static void drawShape(
    Canvas canvas,
    PlanShapeType type,
    Rect rect,
    Paint fillPaint,
    Paint borderPaint,
  ) {
    // Khusus bentuk dasar bawaan Canvas (Optimasi)
    if (type == PlanShapeType.rectangle) {
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
      return;
    } else if (type == PlanShapeType.roundedRect) {
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);
      return;
    } else if (type == PlanShapeType.circle) {
      canvas.drawOval(rect, fillPaint);
      canvas.drawOval(rect, borderPaint);
      return;
    }

    // Bentuk kompleks menggunakan Path
    final path = getPathForType(type, rect);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  static Path getPathForType(PlanShapeType type, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    Path path = Path();

    switch (type) {
      // --- BASIC ---
      case PlanShapeType.triangle:
        path.moveTo(cx, t);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(l, rect.bottom);
        break;
      case PlanShapeType.rightTriangle:
        path.moveTo(l, t);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(l, rect.bottom);
        break;
      case PlanShapeType.diamond:
        path.moveTo(cx, t);
        path.lineTo(rect.right, cy);
        path.lineTo(cx, rect.bottom);
        path.lineTo(l, cy);
        break;
      case PlanShapeType.parallelogram:
        final skew = w * 0.2;
        path.moveTo(l + skew, t);
        path.lineTo(rect.right, t);
        path.lineTo(rect.right - skew, rect.bottom);
        path.lineTo(l, rect.bottom);
        break;
      case PlanShapeType.trapezoid:
        final inset = w * 0.2;
        path.moveTo(l + inset, t);
        path.lineTo(rect.right - inset, t);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(l, rect.bottom);
        break;

      // --- POLYGONS ---
      case PlanShapeType.pentagon:
        _addPolygon(path, cx, cy, math.min(w, h) / 2, 5);
        break;
      case PlanShapeType.hexagon:
        _addPolygon(path, cx, cy, math.min(w, h) / 2, 6);
        break;
      case PlanShapeType.heptagon:
        _addPolygon(path, cx, cy, math.min(w, h) / 2, 7);
        break;
      case PlanShapeType.octagon:
        _addPolygon(path, cx, cy, math.min(w, h) / 2, 8);
        break;
      case PlanShapeType.decagon:
        _addPolygon(path, cx, cy, math.min(w, h) / 2, 10);
        break;

      // --- STARS ---
      case PlanShapeType.star:
        _addStar(path, cx, cy, math.min(w, h) / 2, 5, 2.5);
        break;
      case PlanShapeType.star4:
        _addStar(path, cx, cy, math.min(w, h) / 2, 4, 3.0);
        break;
      case PlanShapeType.star6:
        _addStar(path, cx, cy, math.min(w, h) / 2, 6, 2.5);
        break;
      case PlanShapeType.star8:
        _addStar(path, cx, cy, math.min(w, h) / 2, 8, 2.5);
        break;

      // --- SYMBOLS ---
      case PlanShapeType.heart:
        path.moveTo(cx, rect.bottom);
        path.cubicTo(rect.right, cy + h * 0.1, rect.right, t, cx, t + h * 0.2);
        path.cubicTo(l, t, l, cy + h * 0.1, cx, rect.bottom);
        break;
      case PlanShapeType.cross:
        final thick = math.min(w, h) / 3;
        path.addRect(
          Rect.fromCenter(center: rect.center, width: thick, height: h),
        );
        path.addRect(
          Rect.fromCenter(center: rect.center, width: w, height: thick),
        );
        break;
      case PlanShapeType.check:
        path.moveTo(l + w * 0.1, cy);
        path.lineTo(l + w * 0.4, rect.bottom - h * 0.1);
        path.lineTo(rect.right - w * 0.1, t + h * 0.1);
        // Outline manual sederhana
        path.lineTo(l + w * 0.4, rect.bottom - h * 0.3);
        break;
      case PlanShapeType.cloud:
        path.moveTo(l + w * 0.2, rect.bottom);
        path.quadraticBezierTo(l - w * 0.1, cy, l + w * 0.2, t + h * 0.3);
        path.quadraticBezierTo(
          cx,
          t - h * 0.2,
          rect.right - w * 0.2,
          t + h * 0.3,
        );
        path.quadraticBezierTo(
          rect.right + w * 0.1,
          cy,
          rect.right - w * 0.2,
          rect.bottom,
        );
        break;

      // --- ARROWS ---
      case PlanShapeType.arrowRight:
      case PlanShapeType.blockArrowRight:
        final stemH = h * 0.5;
        final headW = w * 0.4;
        path.moveTo(l, cy - stemH / 2);
        path.lineTo(rect.right - headW, cy - stemH / 2);
        path.lineTo(rect.right - headW, t);
        path.lineTo(rect.right, cy);
        path.lineTo(rect.right - headW, rect.bottom);
        path.lineTo(rect.right - headW, cy + stemH / 2);
        path.lineTo(l, cy + stemH / 2);
        break;
      case PlanShapeType.arrowUp:
        final stemW = w * 0.5;
        final headH = h * 0.4;
        path.moveTo(cx - stemW / 2, rect.bottom);
        path.lineTo(cx - stemW / 2, t + headH);
        path.lineTo(l, t + headH);
        path.lineTo(cx, t);
        path.lineTo(rect.right, t + headH);
        path.lineTo(cx + stemW / 2, t + headH);
        path.lineTo(cx + stemW / 2, rect.bottom);
        break;
      case PlanShapeType.doubleArrowH:
        final stemH = h * 0.4;
        final headW = w * 0.3;
        path.moveTo(l + headW, cy - stemH / 2);
        path.lineTo(rect.right - headW, cy - stemH / 2);
        path.lineTo(rect.right - headW, t);
        path.lineTo(rect.right, cy);
        path.lineTo(rect.right - headW, rect.bottom);
        path.lineTo(rect.right - headW, cy + stemH / 2);
        path.lineTo(l + headW, cy + stemH / 2);
        path.lineTo(l + headW, rect.bottom);
        path.lineTo(l, cy);
        path.lineTo(l + headW, t);
        path.lineTo(l + headW, cy - stemH / 2);
        break;

      // --- ARCHITECTURAL ---
      case PlanShapeType.lShape:
        final thick = math.min(w, h) / 3;
        path.moveTo(l, t);
        path.lineTo(l + thick, t);
        path.lineTo(l + thick, rect.bottom - thick);
        path.lineTo(rect.right, rect.bottom - thick);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(l, rect.bottom);
        break;
      case PlanShapeType.uShape:
        final thick = w / 4;
        path.moveTo(l, t);
        path.lineTo(l + thick, t);
        path.lineTo(l + thick, rect.bottom - thick);
        path.lineTo(rect.right - thick, rect.bottom - thick);
        path.lineTo(rect.right - thick, t);
        path.lineTo(rect.right, t);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(l, rect.bottom);
        break;
      case PlanShapeType.stairs:
        final stepH = h / 4;
        path.addRect(rect); // Frame luar
        for (int i = 1; i < 4; i++) {
          path.addRect(Rect.fromLTWH(l, t + stepH * i, w, 1));
        }
        break;
      case PlanShapeType.iBeam:
        final flangeH = h * 0.15;
        final webW = w * 0.2;
        path.moveTo(l, t);
        path.lineTo(rect.right, t);
        path.lineTo(rect.right, t + flangeH);
        path.lineTo(cx + webW / 2, t + flangeH);
        path.lineTo(cx + webW / 2, rect.bottom - flangeH);
        path.lineTo(rect.right, rect.bottom - flangeH);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(l, rect.bottom);
        path.lineTo(l, rect.bottom - flangeH);
        path.lineTo(cx - webW / 2, rect.bottom - flangeH);
        path.lineTo(cx - webW / 2, t + flangeH);
        path.lineTo(l, t + flangeH);
        break;
      case PlanShapeType.arc:
        path.moveTo(l, rect.bottom);
        path.quadraticBezierTo(cx, t - h * 0.5, rect.right, rect.bottom);
        path.close();
        break;

      // --- FLOWCHART ---
      case PlanShapeType.document:
        path.moveTo(l, t);
        path.lineTo(rect.right, t);
        path.lineTo(rect.right, rect.bottom - h * 0.15);
        path.quadraticBezierTo(
          rect.right - w * 0.25,
          rect.bottom,
          cx,
          rect.bottom - h * 0.15,
        );
        path.quadraticBezierTo(
          l + w * 0.25,
          rect.bottom - h * 0.3,
          l,
          rect.bottom - h * 0.15,
        );
        break;
      case PlanShapeType.database:
        final ovalH = h * 0.2;
        path.addOval(Rect.fromLTWH(l, t, w, ovalH));
        path.moveTo(l, t + ovalH / 2);
        path.lineTo(l, rect.bottom - ovalH / 2);
        path.arcToPoint(
          Offset(rect.right, rect.bottom - ovalH / 2),
          radius: Radius.elliptical(w / 2, ovalH / 2),
          clockwise: false,
        );
        path.lineTo(rect.right, t + ovalH / 2);
        break;

      // --- BUBBLES ---
      case PlanShapeType.bubbleRound:
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(l, t, w, h * 0.8),
            const Radius.circular(12),
          ),
        );
        path.moveTo(cx - w * 0.1, t + h * 0.8);
        path.lineTo(l + w * 0.2, rect.bottom);
        path.lineTo(cx + w * 0.1, t + h * 0.8);
        break;

      default:
        path.addRect(rect);
    }
    path.close();
    return path;
  }

  static void _addPolygon(
    Path path,
    double cx,
    double cy,
    double radius,
    int sides,
  ) {
    final angle = (math.pi * 2) / sides;
    final offset = -math.pi / 2; // Mulai dari atas

    for (int i = 0; i < sides; i++) {
      double x = cx + radius * math.cos(offset + angle * i);
      double y = cy + radius * math.sin(offset + angle * i);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
  }

  static void _addStar(
    Path path,
    double cx,
    double cy,
    double radius,
    int points,
    double insetFactor,
  ) {
    final innerRadius = radius / insetFactor;
    final angle = math.pi / points;
    final offset = -math.pi / 2;

    for (int i = 0; i < points * 2; i++) {
      double r = (i.isEven) ? radius : innerRadius;
      double currAngle = offset + angle * i;
      double x = cx + r * math.cos(currAngle);
      double y = cy + r * math.sin(currAngle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
  }
}
