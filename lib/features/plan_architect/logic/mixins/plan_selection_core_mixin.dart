import 'dart:math';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';
import '../plan_enums.dart'; // <--- TAMBAHKAN BARIS INI

mixin PlanSelectionCoreMixin on PlanVariables, PlanStateMixin {
  void toggleMultiSelectMode() {
    isMultiSelectMode = !isMultiSelectMode;
    if (!isMultiSelectMode) {
      multiSelectedIds.clear();
    }
    selectedId = null; // Reset single selection
    notifyListeners();
  }

  // --- TAMBAHAN: SELECT ALL ---
  void selectAll() {
    isMultiSelectMode = true;
    selectedId = null;
    multiSelectedIds.clear();

    // Masukkan semua ID yang memungkinkan
    for (var w in walls) multiSelectedIds.add(w.id);
    for (var o in objects) multiSelectedIds.add(o.id);
    for (var s in shapes) multiSelectedIds.add(s.id);
    for (var p in paths) multiSelectedIds.add(p.id);
    for (var l in labels) multiSelectedIds.add(l.id);
    for (var g in groups) multiSelectedIds.add(g.id);
    for (var p in portals) multiSelectedIds.add(p.id);

    notifyListeners();
  }

  // --- TAMBAHAN: SELECT IN RECTANGLE (Drag Box) ---
  void selectInRect(Rect rect) {
    // Aktifkan mode multi select jika belum
    if (!isMultiSelectMode) {
      isMultiSelectMode = true;
      selectedId = null;
      // Jangan clear multiSelectedIds jika sudah diaktifkan di onPanStart
    }

    // Gunakan Set untuk menghindari duplikasi
    final Set<String> newSelections = {};

    // 1. Tembok (Cek kedua ujungnya ada di dalam rect)
    for (var w in walls) {
      if (rect.contains(w.start) && rect.contains(w.end)) {
        newSelections.add(w.id);
      }
    }
    // 2. Objek (Cek titik tengah)
    for (var o in objects) {
      if (rect.contains(o.position)) {
        newSelections.add(o.id);
      }
    }
    // 3. Shapes (Cek overlap bounding box)
    for (var s in shapes) {
      if (rect.overlaps(s.rect.inflate(5.0))) {
        // Beri toleransi 5px
        newSelections.add(s.id);
      }
    }
    // 4. Groups
    for (var g in groups) {
      if (rect.contains(g.position)) {
        newSelections.add(g.id);
      }
    }
    // 5. Portals
    for (var p in portals) {
      if (rect.contains(p.position)) {
        newSelections.add(p.id);
      }
    }
    // 6. Labels
    for (var l in labels) {
      if (rect.contains(l.position)) {
        newSelections.add(l.id);
      }
    }
    // 7. Paths (Cek apakah ada titik path yang masuk)
    for (var p in paths) {
      for (var pt in p.points) {
        if (rect.contains(pt)) {
          newSelections.add(p.id);
          break;
        }
      }
    }

    multiSelectedIds.addAll(newSelections); // Tambahkan seleksi baru
    notifyListeners();
  }
  // ------------------------------------------

  void handleSelection(Offset pos) {
    String? hitId;
    // 1. Cek Labels (Prioritas Tertinggi - Layer Atas)
    for (var lbl in labels.reversed) {
      if ((lbl.position - pos).distance < 20.0) {
        hitId = lbl.id;
        break;
      }
    }
    // 2. Cek Portals (Pintu/Jendela)
    if (hitId == null) {
      for (var p in portals.reversed) {
        if ((p.position - pos).distance < (p.width / 2 + 5)) {
          hitId = p.id;
          break;
        }
      }
    }
    // 3. Cek Objects
    if (hitId == null) {
      for (var obj in objects.reversed) {
        if ((obj.position - pos).distance < 25.0) {
          hitId = obj.id;
          break;
        }
      }
    }
    // 4. Cek Groups
    if (hitId == null) {
      for (var grp in groups.reversed) {
        final offset = pos - grp.position;
        final cosA = cos(-grp.rotation);
        final sinA = sin(-grp.rotation);
        final localX = offset.dx * cosA - offset.dy * sinA;
        final localY = offset.dx * sinA + offset.dy * cosA;
        final localPos = Offset(localX, localY);
        final bounds = grp.getBounds();
        if (bounds.inflate(10).contains(localPos)) {
          hitId = grp.id;
          break;
        }
      }
    }
    // 5. Cek Shapes
    if (hitId == null) {
      for (var shp in shapes.reversed) {
        if (shp.rect.contains(pos)) {
          hitId = shp.id;
          break;
        }
      }
    }
    // 6. Cek Paths (Garis Gambar)
    if (hitId == null) {
      for (var path in paths.reversed) {
        if (isPointNearPath(pos, path)) {
          hitId = path.id;
          break;
        }
      }
    }
    // 7. Cek Walls (Prioritas Terendah - Layer Bawah)
    if (hitId == null) {
      for (var wall in walls) {
        if (isPointNearLine(pos, wall.start, wall.end, 15.0)) {
          hitId = wall.id;
          break;
        }
      }
    }

    if (isMultiSelectMode) {
      if (hitId != null) {
        if (multiSelectedIds.contains(hitId)) {
          multiSelectedIds.remove(hitId);
        } else {
          multiSelectedIds.add(hitId);
        }
      }
      selectedId = null;
    } else {
      selectedId = hitId;
      isObjectSelected = hitId != null;
      multiSelectedIds.clear();
    }
    notifyListeners();
  }

  // --- Helper Geometri ---
  bool isPointNearLine(Offset p, Offset a, Offset b, double threshold) {
    double dx = b.dx - a.dx;
    double dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return false;
    double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);
    t = max(0, min(1, t)); // Clamp agar tetap di dalam segmen garis
    Offset closest = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - closest).distance < threshold;
  }

  bool isPointNearPath(Offset p, PlanPath path) {
    if (path.points.length < 2) return false;
    for (int i = 0; i < path.points.length - 1; i++) {
      if (isPointNearLine(p, path.points[i], path.points[i + 1], 10.0)) {
        return true;
      }
    }
    return false;
  }

  // --- Logic Hapus ---
  void deleteSelected() {
    if (selectedId == null && multiSelectedIds.isEmpty) return;
    final idsToDelete = isMultiSelectMode
        ? multiSelectedIds.toList()
        : [selectedId!];

    updateActiveFloor(
      shapes: List.from(shapes)..removeWhere((s) => idsToDelete.contains(s.id)),
      labels: List.from(labels)..removeWhere((l) => idsToDelete.contains(l.id)),
      objects: List.from(objects)
        ..removeWhere((o) => idsToDelete.contains(o.id)),
      paths: List.from(paths)..removeWhere((p) => idsToDelete.contains(p.id)),
      walls: List.from(walls)..removeWhere((w) => idsToDelete.contains(w.id)),
      groups: List.from(groups)..removeWhere((g) => idsToDelete.contains(g.id)),
      portals: List.from(portals)
        ..removeWhere((p) => idsToDelete.contains(p.id)),
    );

    selectedId = null;
    multiSelectedIds.clear();
    saveState();
  }

  Map<String, dynamic>? getSelectedItemData() {
    if (selectedId == null) return null;

    try {
      final p = portals.firstWhere((x) => x.id == selectedId);
      return {
        'id': p.id,
        'title': p.type == PlanPortalType.door ? 'Pintu' : 'Jendela',
        'desc': 'Lebar: ${p.width.toInt()}',
        'type': 'Struktur',
        'isPath': false,
        'nav': null,
      };
    } catch (_) {}

    try {
      final g = groups.firstWhere((x) => x.id == selectedId);
      return {
        'id': g.id,
        'title': g.name,
        'desc': "Grup",
        'type': 'Grup',
        'isPath': false,
        'isGroup': true,
        'nav': null,
      };
    } catch (_) {}
    try {
      final s = shapes.firstWhere((x) => x.id == selectedId);
      return {
        'id': s.id,
        'title': s.name,
        'desc': s.description,
        'type': 'Bentuk',
        'isPath': false,
        'nav': null,
      };
    } catch (_) {}
    try {
      final l = labels.firstWhere((x) => x.id == selectedId);
      return {
        'id': l.id,
        'title': l.text,
        'desc': 'Label',
        'type': 'Label',
        'isPath': false,
        'nav': null,
      };
    } catch (_) {}
    try {
      final o = objects.firstWhere((x) => x.id == selectedId);
      return {
        'id': o.id,
        'title': o.name,
        'desc': o.description,
        'type': 'Interior',
        'isPath': false,
        'nav': o.navTargetFloorId,
      };
    } catch (_) {}
    try {
      final p = paths.firstWhere((x) => x.id == selectedId);
      return {
        'id': p.id,
        'title': p.name,
        'desc': p.description,
        'type': 'Gambar',
        'isPath': true,
        'nav': null,
      };
    } catch (_) {}
    try {
      final w = walls.firstWhere((x) => x.id == selectedId);
      return {
        'id': w.id,
        'title': 'Tembok',
        'desc': w.description,
        'type': 'Struktur',
        'isPath': false,
        'nav': null,
      };
    } catch (_) {}
    return null;
  }
}
