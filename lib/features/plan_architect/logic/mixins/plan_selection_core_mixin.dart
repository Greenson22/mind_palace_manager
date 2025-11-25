// lib/features/plan_architect/logic/mixins/plan_selection_core_mixin.dart
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart'; // Untuk listEquals

import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';
import '../plan_enums.dart';

mixin PlanSelectionCoreMixin on PlanVariables, PlanStateMixin {
  // --- STATE UNTUK CYCLE SELECTION (SELEKSI BERTUMPUK) ---
  List<String> _hitCandidates = []; // Daftar objek yang tertumpuk di titik tap
  int _hitCandidateIndex = 0; // Indeks objek yang sedang dipilih

  void toggleMultiSelectMode() {
    isMultiSelectMode = !isMultiSelectMode;
    if (!isMultiSelectMode) {
      multiSelectedIds.clear();
    }
    selectedId = null;
    _hitCandidates.clear(); // Reset cycle saat mode berubah
    notifyListeners();
  }

  void selectAll() {
    isMultiSelectMode = true;
    selectedId = null;
    multiSelectedIds.clear();
    for (var w in walls) multiSelectedIds.add(w.id);
    for (var o in objects) multiSelectedIds.add(o.id);
    for (var s in shapes) multiSelectedIds.add(s.id);
    for (var p in paths) multiSelectedIds.add(p.id);
    for (var l in labels) multiSelectedIds.add(l.id);
    for (var g in groups) multiSelectedIds.add(g.id);
    for (var p in portals) multiSelectedIds.add(p.id);
    notifyListeners();
  }

  void selectInRect(Rect rect) {
    if (!isMultiSelectMode) {
      isMultiSelectMode = true;
      selectedId = null;
    }
    final Set<String> newSelections = {};
    for (var w in walls) {
      if (rect.contains(w.start) && rect.contains(w.end)) {
        newSelections.add(w.id);
      }
    }
    for (var o in objects) {
      if (rect.contains(o.position)) newSelections.add(o.id);
    }
    for (var s in shapes) {
      if (rect.overlaps(s.rect.inflate(5.0))) newSelections.add(s.id);
    }
    for (var g in groups) {
      if (rect.contains(g.position)) newSelections.add(g.id);
    }
    for (var p in portals) {
      if (rect.contains(p.position)) newSelections.add(p.id);
    }
    for (var l in labels) {
      if (rect.contains(l.position)) newSelections.add(l.id);
    }
    for (var p in paths) {
      for (var pt in p.points) {
        if (rect.contains(pt)) {
          newSelections.add(p.id);
          break;
        }
      }
    }
    multiSelectedIds.addAll(newSelections);
    notifyListeners();
  }

  Map<String, String>? findNavigableItemAt(Offset pos) {
    for (var p in portals.reversed) {
      if ((p.position - pos).distance < (p.width / 2 + 5)) {
        if (p.navTargetFloorId != null) {
          return {'id': p.id, 'targetPlanId': p.navTargetFloorId!};
        }
        return null;
      }
    }
    for (var obj in objects.reversed) {
      if ((obj.position - pos).distance < 25.0) {
        if (obj.navTargetFloorId != null) {
          return {'id': obj.id, 'targetPlanId': obj.navTargetFloorId!};
        }
        return null;
      }
    }
    for (var wall in walls) {
      if (isPointNearLine(pos, wall.start, wall.end, 15.0)) {
        if (wall.navTargetFloorId != null) {
          return {'id': wall.id, 'targetPlanId': wall.navTargetFloorId!};
        }
        return null;
      }
    }
    return null;
  }

  void handleSelection(Offset pos) {
    // Kumpulkan SEMUA item yang terkena tap (Hit Test) dalam urutan Layer (Atas ke Bawah)
    List<String> newHits = [];

    // 1. Labels (Paling Atas)
    for (var lbl in labels.reversed) {
      if ((lbl.position - pos).distance < 20.0) {
        newHits.add(lbl.id);
      }
    }
    // 2. Portals (Pintu/Jendela)
    for (var p in portals.reversed) {
      if ((p.position - pos).distance < (p.width / 2 + 5)) {
        newHits.add(p.id);
      }
    }
    // 3. Objects (Interior)
    for (var obj in objects.reversed) {
      if ((obj.position - pos).distance < 25.0) {
        newHits.add(obj.id);
      }
    }
    // 4. Groups
    for (var grp in groups.reversed) {
      final offset = pos - grp.position;
      final cosA = cos(-grp.rotation);
      final sinA = sin(-grp.rotation);
      final localX = offset.dx * cosA - offset.dy * sinA;
      final localY = offset.dx * sinA + offset.dy * cosA;
      final localPos = Offset(localX, localY);
      final bounds = grp.getBounds();
      if (bounds.inflate(10).contains(localPos)) {
        newHits.add(grp.id);
      }
    }
    // 5. Shapes
    for (var shp in shapes.reversed) {
      if (shp.rect.contains(pos)) {
        newHits.add(shp.id);
      }
    }
    // 6. Paths (Gambar Garis)
    for (var path in paths.reversed) {
      if (isPointNearPath(pos, path)) {
        newHits.add(path.id);
      }
    }
    // 7. Walls (Tembok - Layer Paling Bawah)
    for (var wall in walls.reversed) {
      if (isPointNearLine(pos, wall.start, wall.end, 15.0)) {
        newHits.add(wall.id);
      }
    }

    // --- LOGIKA SELECTION CYCLING (PILAH PILIH TUMPUKAN) ---
    if (isMultiSelectMode) {
      // Mode Multi: Toggle item teratas saja untuk konsistensi
      if (newHits.isNotEmpty) {
        final hitId = newHits.first;
        if (multiSelectedIds.contains(hitId)) {
          multiSelectedIds.remove(hitId);
        } else {
          multiSelectedIds.add(hitId);
        }
      }
      selectedId = null;
    } else {
      // Mode Single: Fitur Cycle Aktif
      if (newHits.isEmpty) {
        // Klik area kosong -> Deselect semua
        selectedId = null;
        isObjectSelected = false;
        multiSelectedIds.clear();
        _hitCandidates.clear();
      } else {
        // Cek apakah user mengetuk tumpukan yang sama dengan sebelumnya
        if (listEquals(newHits, _hitCandidates)) {
          // Ya, Cycle ke item berikutnya dalam daftar
          _hitCandidateIndex = (_hitCandidateIndex + 1) % newHits.length;
        } else {
          // Tidak, ini tumpukan baru atau klik pertama
          _hitCandidates = newHits;
          _hitCandidateIndex = 0; // Reset ke item paling atas
        }

        // Set item yang terpilih berdasarkan index cycle
        selectedId = _hitCandidates[_hitCandidateIndex];
        isObjectSelected = true;
        multiSelectedIds.clear();
      }
    }

    notifyListeners();
  }

  bool isPointNearLine(Offset p, Offset a, Offset b, double threshold) {
    double dx = b.dx - a.dx;
    double dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return false;
    double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);
    t = max(0, min(1, t));
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
    _hitCandidates.clear(); // Bersihkan cache cycle saat hapus
    saveState();
  }

  Map<String, List<Map<String, dynamic>>> getRawSelectedItems() {
    if (selectedId == null && multiSelectedIds.isEmpty) return {};
    final ids = isMultiSelectMode ? multiSelectedIds.toList() : [selectedId!];
    final Map<String, List<Map<String, dynamic>>> result = {
      'objects': [],
      'walls': [],
      'portals': [],
      'shapes': [],
      'labels': [],
      'paths': [],
      'groups': [],
    };
    for (var item in objects) {
      if (ids.contains(item.id)) result['objects']!.add(item.toJson());
    }
    for (var item in walls) {
      if (ids.contains(item.id)) result['walls']!.add(item.toJson());
    }
    for (var item in portals) {
      if (ids.contains(item.id)) result['portals']!.add(item.toJson());
    }
    for (var item in shapes) {
      if (ids.contains(item.id)) result['shapes']!.add(item.toJson());
    }
    for (var item in labels) {
      if (ids.contains(item.id)) result['labels']!.add(item.toJson());
    }
    for (var item in paths) {
      if (ids.contains(item.id)) result['paths']!.add(item.toJson());
    }
    for (var item in groups) {
      if (ids.contains(item.id)) result['groups']!.add(item.toJson());
    }
    result.removeWhere((key, value) => value.isEmpty);
    return result;
  }

  String? _resolvePath(String? path) {
    if (path == null) return null;
    if (buildingDirectory != null && !p.isAbsolute(path)) {
      return p.join(buildingDirectory!.path, path);
    }
    return path;
  }

  Map<String, dynamic>? getSelectedItemData() {
    if (selectedId == null) return null;

    try {
      final p = portals.firstWhere((x) => x.id == selectedId);
      return {
        'id': p.id,
        'title': p.type == PlanPortalType.door ? 'Pintu' : 'Jendela',
        'desc': p.description.isNotEmpty
            ? p.description
            : 'Lebar: ${p.width.toInt()}',
        'type': 'Struktur',
        'isPath': false,
        'nav': p.navTargetFloorId,
        'refImage': _resolvePath(p.referenceImage),
      };
    } catch (_) {}

    try {
      final g = groups.firstWhere((x) => x.id == selectedId);
      return {
        'id': g.id,
        'title': g.name,
        'desc': g.description,
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
        'refImage': _resolvePath(s.referenceImage),
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
        'refImage': _resolvePath(o.referenceImage),
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
        'nav': w.navTargetFloorId,
        'refImage': _resolvePath(w.referenceImage),
      };
    } catch (_) {}
    return null;
  }
}
