// lib/features/plan_architect/logic/mixins/plan_selection_mixin.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';
import '../plan_enums.dart'; // Import enum

mixin PlanSelectionMixin on PlanVariables, PlanStateMixin {
  void toggleMultiSelectMode() {
    isMultiSelectMode = !isMultiSelectMode;
    if (!isMultiSelectMode) {
      multiSelectedIds.clear();
    }
    selectedId = null; // Reset single selection
    notifyListeners();
  }

  void handleSelection(Offset pos) {
    String? hitId;
    for (var lbl in labels.reversed) {
      if ((lbl.position - pos).distance < 20.0) {
        hitId = lbl.id;
        break;
      }
    }
    // Cek Portals (Pintu/Jendela)
    if (hitId == null) {
      for (var p in portals.reversed) {
        if ((p.position - pos).distance < (p.width / 2 + 5)) {
          hitId = p.id;
          break;
        }
      }
    }
    if (hitId == null) {
      for (var obj in objects.reversed) {
        if ((obj.position - pos).distance < 25.0) {
          hitId = obj.id;
          break;
        }
      }
    }
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
    if (hitId == null) {
      for (var shp in shapes.reversed) {
        if (shp.rect.contains(pos)) {
          hitId = shp.id;
          break;
        }
      }
    }
    if (hitId == null) {
      for (var path in paths.reversed) {
        if (isPointNearPath(pos, path)) {
          hitId = path.id;
          break;
        }
      }
    }
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
      if (isPointNearLine(p, path.points[i], path.points[i + 1], 10.0))
        return true;
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
    saveState();
  }

  void nudgeSelection(Offset delta) {
    moveSelectedItem(delta);
    notifyListeners();
  }

  void moveSelectedItem(Offset delta) {
    // Multi Select Move
    if (isMultiSelectMode) {
      bool changed = false;
      List<PlanShape> newShapes = List.from(shapes);
      List<PlanObject> newObjects = List.from(objects);
      List<Wall> newWalls = List.from(walls);
      List<PlanLabel> newLabels = List.from(labels);
      List<PlanPath> newPaths = List.from(paths);
      List<PlanGroup> newGroups = List.from(groups);
      List<PlanPortal> newPortals = List.from(portals);

      for (var id in multiSelectedIds) {
        final sIdx = newShapes.indexWhere((x) => x.id == id);
        if (sIdx != -1) {
          newShapes[sIdx] = newShapes[sIdx].moveBy(delta);
          changed = true;
        }

        final oIdx = newObjects.indexWhere((x) => x.id == id);
        if (oIdx != -1) {
          newObjects[oIdx] = newObjects[oIdx].moveBy(delta);
          changed = true;
        }

        final wIdx = newWalls.indexWhere((x) => x.id == id);
        if (wIdx != -1) {
          newWalls[wIdx] = newWalls[wIdx].moveBy(delta);
          changed = true;
        }

        final lIdx = newLabels.indexWhere((x) => x.id == id);
        if (lIdx != -1) {
          newLabels[lIdx] = newLabels[lIdx].moveBy(delta);
          changed = true;
        }

        final pIdx = newPaths.indexWhere((x) => x.id == id);
        if (pIdx != -1) {
          newPaths[pIdx] = newPaths[pIdx].moveBy(delta);
          changed = true;
        }

        final gIdx = newGroups.indexWhere((x) => x.id == id);
        if (gIdx != -1) {
          newGroups[gIdx] = newGroups[gIdx].moveBy(delta);
          changed = true;
        }

        final portIdx = newPortals.indexWhere((x) => x.id == id);
        if (portIdx != -1) {
          newPortals[portIdx] = newPortals[portIdx].moveBy(delta);
          changed = true;
        }
      }
      if (changed) {
        updateActiveFloor(
          shapes: newShapes,
          objects: newObjects,
          walls: newWalls,
          labels: newLabels,
          paths: newPaths,
          groups: newGroups,
          portals: newPortals,
        );
      }
      return;
    }

    // Single Select Move
    if (selectedId == null) return;

    List<PlanPortal> newPortals = List.from(portals);
    final portIdx = newPortals.indexWhere((p) => p.id == selectedId);
    if (portIdx != -1) {
      newPortals[portIdx] = newPortals[portIdx].moveBy(delta);
      updateActiveFloor(portals: newPortals);
      return;
    }

    List<PlanGroup> newGroups = List.from(groups);
    final gIdx = newGroups.indexWhere((g) => g.id == selectedId);
    if (gIdx != -1) {
      newGroups[gIdx] = newGroups[gIdx].moveBy(delta);
      updateActiveFloor(groups: newGroups);
      return;
    }
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes[shpIdx] = newShapes[shpIdx].moveBy(delta);
      updateActiveFloor(shapes: newShapes);
      return;
    }
    List<PlanObject> newObjects = List.from(objects);
    final objIdx = newObjects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjects[objIdx] = newObjects[objIdx].moveBy(delta);
      updateActiveFloor(objects: newObjects);
      return;
    }
    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      newWalls[wIdx] = newWalls[wIdx].moveBy(delta);
      updateActiveFloor(walls: newWalls);
      return;
    }
    List<PlanLabel> newLabels = List.from(labels);
    final lIdx = newLabels.indexWhere((l) => l.id == selectedId);
    if (lIdx != -1) {
      newLabels[lIdx] = newLabels[lIdx].moveBy(delta);
      updateActiveFloor(labels: newLabels);
      return;
    }
    List<PlanPath> newPaths = List.from(paths);
    final pIdx = newPaths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      newPaths[pIdx] = newPaths[pIdx].moveBy(delta);
      updateActiveFloor(paths: newPaths);
      return;
    }
  }

  void moveAllContent(Offset delta) {
    final newWalls = walls.map((w) => w.moveBy(delta)).toList();
    final newObjects = objects.map((o) => o.moveBy(delta)).toList();
    final newPaths = paths.map((p) => p.moveBy(delta)).toList();
    final newLabels = labels.map((l) => l.moveBy(delta)).toList();
    final newShapes = shapes.map((s) => s.moveBy(delta)).toList();
    final newGroups = groups.map((g) => g.moveBy(delta)).toList();
    final newPortals = portals.map((p) => p.moveBy(delta)).toList();
    updateActiveFloor(
      walls: newWalls,
      objects: newObjects,
      paths: newPaths,
      labels: newLabels,
      shapes: newShapes,
      groups: newGroups,
      portals: newPortals,
    );
  }

  void flipSelected(bool horizontal) {
    if (selectedId == null && multiSelectedIds.isEmpty) return;

    Set<String> targetIds = {};
    if (isMultiSelectMode) {
      targetIds.addAll(multiSelectedIds);
    } else {
      if (selectedId != null) targetIds.add(selectedId!);
    }
    if (targetIds.isEmpty) return;

    // Hitung Pivot (Titik Tengah Seleksi)
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    int count = 0;

    void includePoint(double x, double y) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      count++;
    }

    for (var id in targetIds) {
      try {
        final w = walls.firstWhere((e) => e.id == id);
        includePoint(w.start.dx, w.start.dy);
        includePoint(w.end.dx, w.end.dy);
        continue;
      } catch (_) {}
      try {
        final p = portals.firstWhere((e) => e.id == id);
        includePoint(p.position.dx, p.position.dy);
        continue;
      } catch (_) {}
      try {
        final o = objects.firstWhere((e) => e.id == id);
        includePoint(o.position.dx, o.position.dy);
        continue;
      } catch (_) {}
      try {
        final s = shapes.firstWhere((e) => e.id == id);
        includePoint(s.rect.center.dx, s.rect.center.dy);
        continue;
      } catch (_) {}
      try {
        final g = groups.firstWhere((e) => e.id == id);
        includePoint(g.position.dx, g.position.dy);
        continue;
      } catch (_) {}
      try {
        final p = paths.firstWhere((e) => e.id == id);
        for (var pt in p.points) includePoint(pt.dx, pt.dy);
        continue;
      } catch (_) {}
    }

    if (count == 0) return;
    final pivot = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    Offset reflectPoint(Offset p) {
      if (horizontal) {
        // Mirror terhadap sumbu Y di titik pivot (Ubah X)
        return Offset(pivot.dx - (p.dx - pivot.dx), p.dy);
      } else {
        // Mirror terhadap sumbu X di titik pivot (Ubah Y)
        return Offset(p.dx, pivot.dy - (p.dy - pivot.dy));
      }
    }

    // Lakukan Flip
    List<Wall> newWalls = List.from(walls);
    List<PlanPortal> newPortals = List.from(portals);
    List<PlanObject> newObjs = List.from(objects);
    List<PlanShape> newShapes = List.from(shapes);
    List<PlanGroup> newGroups = List.from(groups);
    List<PlanPath> newPaths = List.from(paths);
    bool changed = false;

    // 1. Flip Tembok & Path (Hanya koordinat)
    for (int i = 0; i < newWalls.length; i++) {
      if (targetIds.contains(newWalls[i].id)) {
        newWalls[i] = newWalls[i].copyWith(
          start: reflectPoint(newWalls[i].start),
          end: reflectPoint(newWalls[i].end),
        );
        changed = true;
      }
    }
    for (int i = 0; i < newPaths.length; i++) {
      if (targetIds.contains(newPaths[i].id)) {
        final flippedPoints = newPaths[i].points
            .map((pt) => reflectPoint(pt))
            .toList();
        newPaths[i] = newPaths[i].copyWith(points: flippedPoints);
        changed = true;
      }
    }

    // 2. Flip Objek, Grup, Shape, Portal
    void flipItem(dynamic item, Function(dynamic) updateList) {
      final newPos = reflectPoint(item.position);

      double newRot = item.rotation;
      bool newFlipX = item.flipX;

      newFlipX = !newFlipX;

      if (horizontal) {
        newRot = -newRot;
      } else {
        newRot = pi - newRot;
      }

      // Khusus Shape (karena pakai Rect)
      if (item is PlanShape) {
        final oldCenter = item.rect.center;
        final finalPos = reflectPoint(oldCenter); // Posisi baru center
        final offset = finalPos - oldCenter;
        updateList(
          item.copyWith(
            rect: item.rect.shift(offset),
            rotation: newRot,
            flipX: newFlipX,
          ),
        );
      } else {
        updateList(
          item.copyWith(position: newPos, rotation: newRot, flipX: newFlipX),
        );
      }
    }

    // Update Portals
    for (int i = 0; i < newPortals.length; i++) {
      if (targetIds.contains(newPortals[i].id)) {
        flipItem(newPortals[i], (newItem) => newPortals[i] = newItem);
        changed = true;
      }
    }

    // Update Objects
    for (int i = 0; i < newObjs.length; i++) {
      if (targetIds.contains(newObjs[i].id)) {
        flipItem(newObjs[i], (newItem) => newObjs[i] = newItem);
        changed = true;
      }
    }

    // Update Groups
    for (int i = 0; i < newGroups.length; i++) {
      if (targetIds.contains(newGroups[i].id)) {
        flipItem(newGroups[i], (newItem) => newGroups[i] = newItem);
        changed = true;
      }
    }

    // Update Shapes
    for (int i = 0; i < newShapes.length; i++) {
      if (targetIds.contains(newShapes[i].id)) {
        flipItem(newShapes[i], (newItem) => newShapes[i] = newItem);
        changed = true;
      }
    }

    if (changed) {
      updateActiveFloor(
        walls: newWalls,
        portals: newPortals,
        objects: newObjs,
        groups: newGroups,
        shapes: newShapes,
        paths: newPaths,
      );
      saveState();
    }
  }

  void createGroupFromSelection() {
    if (multiSelectedIds.isEmpty && selectedId == null) return;
    final idsToGroup = isMultiSelectMode
        ? multiSelectedIds.toList()
        : [selectedId!];
    if (idsToGroup.isEmpty) return;

    List<PlanObject> selObjects = objects
        .where((e) => idsToGroup.contains(e.id))
        .toList();
    List<PlanShape> selShapes = shapes
        .where((e) => idsToGroup.contains(e.id))
        .toList();
    List<PlanPath> selPaths = paths
        .where((e) => idsToGroup.contains(e.id))
        .toList();
    List<PlanLabel> selLabels = labels
        .where((e) => idsToGroup.contains(e.id))
        .toList();

    if (selObjects.isEmpty &&
        selShapes.isEmpty &&
        selPaths.isEmpty &&
        selLabels.isEmpty)
      return;

    double sumX = 0, sumY = 0;
    int count = 0;

    for (var o in selObjects) {
      sumX += o.position.dx;
      sumY += o.position.dy;
      count++;
    }
    for (var s in selShapes) {
      sumX += s.rect.center.dx;
      sumY += s.rect.center.dy;
      count++;
    }
    for (var p in selPaths) {
      if (p.points.isNotEmpty) {
        sumX += p.points.first.dx;
        sumY += p.points.first.dy;
        count++;
      }
    }
    for (var l in selLabels) {
      sumX += l.position.dx;
      sumY += l.position.dy;
      count++;
    }

    if (count == 0) return;
    final groupCenter = Offset(sumX / count, sumY / count);

    final newObjects = selObjects
        .map((e) => e.copyWith(position: e.position - groupCenter))
        .toList();
    final newLabels = selLabels
        .map((e) => e.copyWith(position: e.position - groupCenter))
        .toList();
    final newShapes = selShapes
        .map((e) => e.copyWith(rect: e.rect.shift(-groupCenter)))
        .toList();
    final newPaths = selPaths.map((e) => e.moveBy(-groupCenter)).toList();

    final newGroup = PlanGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: groupCenter,
      objects: newObjects,
      shapes: newShapes,
      paths: newPaths,
      labels: newLabels,
      name: "Grup Baru",
    );

    updateActiveFloor(
      objects: objects.where((e) => !idsToGroup.contains(e.id)).toList(),
      shapes: shapes.where((e) => !idsToGroup.contains(e.id)).toList(),
      paths: paths.where((e) => !idsToGroup.contains(e.id)).toList(),
      labels: labels.where((e) => !idsToGroup.contains(e.id)).toList(),
      groups: [...groups, newGroup],
    );
    multiSelectedIds.clear();
    isMultiSelectMode = false;
    selectedId = newGroup.id;
    saveState();
  }

  void ungroupSelected() {
    if (selectedId == null) return;
    int grpIdx = groups.indexWhere((g) => g.id == selectedId);
    if (grpIdx == -1) return;
    final group = groups[grpIdx];
    final restoredObjects = group.objects
        .map((e) => e.copyWith(position: e.position + group.position))
        .toList();
    final restoredLabels = group.labels
        .map((e) => e.copyWith(position: e.position + group.position))
        .toList();
    final restoredShapes = group.shapes
        .map((e) => e.copyWith(rect: e.rect.shift(group.position)))
        .toList();
    final restoredPaths = group.paths
        .map((e) => e.moveBy(group.position))
        .toList();

    List<PlanGroup> newGroups = List.from(groups)..removeAt(grpIdx);
    updateActiveFloor(
      groups: newGroups,
      objects: [...objects, ...restoredObjects],
      shapes: [...shapes, ...restoredShapes],
      paths: [...paths, ...restoredPaths],
      labels: [...labels, ...restoredLabels],
    );
    selectedId = null;
    saveState();
  }

  void duplicateSelected() {
    if (selectedId == null) return;
    final offset = const Offset(20, 20);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final grp = groups.firstWhere((g) => g.id == selectedId);
      updateActiveFloor(
        groups: [
          ...groups,
          grp.copyWith(id: newId, position: grp.position + offset),
        ],
      );
      selectedId = newId;
      saveState();
      return;
    } catch (_) {}

    try {
      final obj = objects.firstWhere((o) => o.id == selectedId);
      updateActiveFloor(
        objects: [
          ...objects,
          obj.copyWith(id: newId, position: obj.position + offset),
        ],
      );
    } catch (_) {}

    try {
      final shp = shapes.firstWhere((s) => s.id == selectedId);
      updateActiveFloor(
        shapes: [
          ...shapes,
          shp.copyWith(id: newId, rect: shp.rect.shift(offset)),
        ],
      );
    } catch (_) {}

    try {
      final wall = walls.firstWhere((w) => w.id == selectedId);
      updateActiveFloor(
        walls: [
          ...walls,
          wall.copyWith(
            id: newId,
            start: wall.start + offset,
            end: wall.end + offset,
          ),
        ],
      );
    } catch (_) {}

    try {
      final pth = paths.firstWhere((p) => p.id == selectedId);
      updateActiveFloor(
        paths: [
          ...paths,
          pth.moveBy(offset).copyWith(id: newId),
        ],
      );
    } catch (_) {}

    try {
      final lbl = labels.firstWhere((l) => l.id == selectedId);
      updateActiveFloor(
        labels: [
          ...labels,
          lbl.moveBy(offset).copyWith(id: newId),
        ],
      );
    } catch (_) {}

    try {
      final prt = portals.firstWhere((p) => p.id == selectedId);
      updateActiveFloor(
        portals: [
          ...portals,
          prt.copyWith(id: newId, position: prt.position + offset),
        ],
      );
    } catch (_) {}

    selectedId = newId;
    saveState();
  }

  // --- Rotasi 90 Derajat (Biasa) ---
  void rotateSelected() {
    if (selectedId == null) return;

    // 1. Rotasi Group
    List<PlanGroup> newGroups = List.from(groups);
    final gIdx = newGroups.indexWhere((g) => g.id == selectedId);
    if (gIdx != -1) {
      newGroups[gIdx] = newGroups[gIdx].copyWith(
        rotation: newGroups[gIdx].rotation + (pi / 2),
      );
      updateActiveFloor(groups: newGroups);
      saveState();
      return;
    }

    // 2. Rotasi Object
    List<PlanObject> newObjs = List.from(objects);
    final objIdx = newObjs.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjs[objIdx] = newObjs[objIdx].copyWith(
        rotation: newObjs[objIdx].rotation + (pi / 2),
      );
      updateActiveFloor(objects: newObjs);
      saveState();
      return;
    }

    // 3. Rotasi Shape
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes[shpIdx] = newShapes[shpIdx].copyWith(
        rotation: newShapes[shpIdx].rotation + (pi / 2),
      );
      updateActiveFloor(shapes: newShapes);
      saveState();
      return;
    }

    // 4. Rotasi Portal (Pintu/Jendela)
    List<PlanPortal> newPortals = List.from(portals);
    final pIdx = newPortals.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      newPortals[pIdx] = newPortals[pIdx].copyWith(
        rotation: newPortals[pIdx].rotation + (pi / 4),
      );
      updateActiveFloor(portals: newPortals);
      saveState();
      return;
    }

    // 5. Rotasi Tembok (Wall)
    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      final w = newWalls[wIdx];
      final center = (w.start + w.end) / 2;

      // Rumus Rotasi 90 derajat
      Offset rotatePoint(Offset p, Offset c) {
        final dx = p.dx - c.dx;
        final dy = p.dy - c.dy;
        return Offset(c.dx - dy, c.dy + dx);
      }

      newWalls[wIdx] = w.copyWith(
        start: rotatePoint(w.start, center),
        end: rotatePoint(w.end, center),
      );
      updateActiveFloor(walls: newWalls);
      saveState();
      return;
    }

    // 6. Rotasi Path (Gambar)
    List<PlanPath> newPaths = List.from(paths);
    final pathIdx = newPaths.indexWhere((p) => p.id == selectedId);
    if (pathIdx != -1) {
      final p = newPaths[pathIdx];
      double minX = double.infinity, maxX = double.negativeInfinity;
      double minY = double.infinity, maxY = double.negativeInfinity;
      for (var pt in p.points) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
      final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);

      Offset rotatePoint(Offset pt, Offset c) {
        final dx = pt.dx - c.dx;
        final dy = pt.dy - c.dy;
        return Offset(c.dx - dy, c.dy + dx);
      }

      final newPoints = p.points.map((pt) => rotatePoint(pt, center)).toList();
      newPaths[pathIdx] = p.copyWith(points: newPoints);
      updateActiveFloor(paths: newPaths);
      saveState();
      return;
    }
  }

  // --- BARU: Rotasi Spesifik (Detail/Derajat) ---
  void setSelectionRotation(double radians) {
    if (selectedId == null) return;

    // 1. Rotasi Group
    List<PlanGroup> newGroups = List.from(groups);
    final gIdx = newGroups.indexWhere((g) => g.id == selectedId);
    if (gIdx != -1) {
      newGroups[gIdx] = newGroups[gIdx].copyWith(rotation: radians);
      updateActiveFloor(groups: newGroups);
      saveState();
      return;
    }

    // 2. Rotasi Object
    List<PlanObject> newObjs = List.from(objects);
    final objIdx = newObjs.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjs[objIdx] = newObjs[objIdx].copyWith(rotation: radians);
      updateActiveFloor(objects: newObjs);
      saveState();
      return;
    }

    // 3. Rotasi Shape
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes[shpIdx] = newShapes[shpIdx].copyWith(rotation: radians);
      updateActiveFloor(shapes: newShapes);
      saveState();
      return;
    }

    // 4. Rotasi Portal
    List<PlanPortal> newPortals = List.from(portals);
    final pIdx = newPortals.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      newPortals[pIdx] = newPortals[pIdx].copyWith(rotation: radians);
      updateActiveFloor(portals: newPortals);
      saveState();
      return;
    }

    // 5. Rotasi Tembok (Complex: Calculate delta angle & rotate around center)
    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      final w = newWalls[wIdx];
      final double dx = w.end.dx - w.start.dx;
      final double dy = w.end.dy - w.start.dy;
      final double currentAngle = atan2(dy, dx);
      final double deltaAngle = radians - currentAngle;

      final center = (w.start + w.end) / 2;

      Offset rotatePoint(Offset p, Offset c, double angle) {
        final x = p.dx - c.dx;
        final y = p.dy - c.dy;
        final nx = x * cos(angle) - y * sin(angle);
        final ny = x * sin(angle) + y * cos(angle);
        return Offset(nx + c.dx, ny + c.dy);
      }

      newWalls[wIdx] = w.copyWith(
        start: rotatePoint(w.start, center, deltaAngle),
        end: rotatePoint(w.end, center, deltaAngle),
      );
      updateActiveFloor(walls: newWalls);
      saveState();
      return;
    }

    // 6. Rotasi Path (Complex: Rotate points around center)
    // Catatan: Path tidak menyimpan properti 'rotation', jadi ini
    // akan memutar titiknya secara permanen. UI Slider mungkin 'jumpy'
    // jika tidak hati-hati, tapi untuk 'set value' ini oke.
    // Opsi: Untuk Path, kita mungkin hanya dukung +90, tapi jika dipaksa:
    // Kita butuh rotasi delta relatif, bukan absolute set.
    // Skip Path untuk setRotation (absolute) demi kestabilan,
    // atau implementasi rotasi relatif jika diperlukan nanti.
  }

  void updateSelectedAttribute({
    Color? color,
    double? stroke,
    String? desc,
    String? name,
    String? navTarget,
    bool? isFilled,
  }) {
    if (selectedId == null) return;

    List<PlanGroup> newGroups = List.from(groups);
    final gIdx = newGroups.indexWhere((g) => g.id == selectedId);
    if (gIdx != -1) {
      newGroups[gIdx] = newGroups[gIdx].copyWith(name: name);
      updateActiveFloor(groups: newGroups);
      saveState();
      return;
    }

    List<PlanObject> newObjects = List.from(objects);
    final objIdx = newObjects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjects[objIdx] = newObjects[objIdx].copyWith(
        color: color,
        description: desc,
        name: name,
        navTargetFloorId: navTarget,
        size: stroke,
      );
      updateActiveFloor(objects: newObjects);
      saveState();
      return;
    }

    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      newWalls[wIdx] = newWalls[wIdx].copyWith(
        color: color,
        thickness: stroke,
        description: desc,
      );
      updateActiveFloor(walls: newWalls);
      saveState();
      return;
    }

    List<PlanPath> newPaths = List.from(paths);
    final pIdx = newPaths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      newPaths[pIdx] = newPaths[pIdx].copyWith(
        color: color,
        strokeWidth: stroke,
        description: desc,
        name: name,
      );
      updateActiveFloor(paths: newPaths);
      saveState();
      return;
    }

    List<PlanLabel> newLabels = List.from(labels);
    final lIdx = newLabels.indexWhere((l) => l.id == selectedId);
    if (lIdx != -1) {
      newLabels[lIdx] = newLabels[lIdx].copyWith(
        color: color,
        text: name,
        fontSize: stroke,
      );
      updateActiveFloor(labels: newLabels);
      saveState();
      return;
    }

    List<PlanShape> newShapes = List.from(shapes);
    final sIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (sIdx != -1) {
      PlanShape oldShape = newShapes[sIdx];
      Rect newRect = oldShape.rect;
      if (stroke != null) {
        final center = oldShape.rect.center;
        final aspectRatio = oldShape.rect.height / oldShape.rect.width;
        final newWidth = stroke * 10;
        final newHeight = newWidth * aspectRatio;
        newRect = Rect.fromCenter(
          center: center,
          width: newWidth,
          height: newHeight,
        );
      }
      newShapes[sIdx] = oldShape.copyWith(
        color: color,
        description: desc,
        name: name,
        rect: stroke != null ? newRect : null,
        isFilled: isFilled,
      );
      updateActiveFloor(shapes: newShapes);
      saveState();
      return;
    }

    List<PlanPortal> newPortals = List.from(portals);
    final portIdx = newPortals.indexWhere((p) => p.id == selectedId);
    if (portIdx != -1) {
      newPortals[portIdx] = newPortals[portIdx].copyWith(
        color: color,
        width: stroke,
      );
      updateActiveFloor(portals: newPortals);
      saveState();
      return;
    }
  }

  void updateSelectedWallLength(double newLengthInMeters) {
    if (selectedId == null) return;
    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      final oldWall = newWalls[wIdx];
      final double newLengthPx = newLengthInMeters * 40.0;
      final double dx = oldWall.end.dx - oldWall.start.dx;
      final double dy = oldWall.end.dy - oldWall.start.dy;
      final double currentLen = sqrt(dx * dx + dy * dy);
      if (currentLen == 0) return;
      final double unitX = dx / currentLen;
      final double unitY = dy / currentLen;
      final Offset newEnd = Offset(
        oldWall.start.dx + (unitX * newLengthPx),
        oldWall.start.dy + (unitY * newLengthPx),
      );
      newWalls[wIdx] = oldWall.copyWith(end: newEnd);
      updateActiveFloor(walls: newWalls);
      saveState();
    }
  }

  void updateSelectedColor(Color color) =>
      updateSelectedAttribute(color: color);
  void updateSelectedStrokeWidth(double width) =>
      updateSelectedAttribute(stroke: width);

  void bringToFront() {
    if (selectedId == null) return;
    // ... (existing logic, not modified)
  }

  void sendToBack() {
    // ... (existing logic, not modified)
  }

  void saveCurrentSelectionToLibrary() {
    if (selectedId == null) return;
    final pathIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pathIdx != -1) {
      savedCustomInteriors.add(paths[pathIdx].copyWith(isSavedAsset: true));
      notifyListeners();
      return;
    }
    final grpIdx = groups.indexWhere((g) => g.id == selectedId);
    if (grpIdx != -1) {
      savedCustomInteriors.add(groups[grpIdx].copyWith(isSavedAsset: true));
      notifyListeners();
      return;
    }
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
        'rotation': p.rotation, // Tambahkan rotation
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
        'rotation': g.rotation, // Tambahkan rotation
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
        'rotation': s.rotation, // Tambahkan rotation
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
        'rotation': 0.0, // Label belum dukung rotasi
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
        'rotation': o.rotation, // Tambahkan rotation
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
      // Hitung rotasi tembok manual
      final dx = w.end.dx - w.start.dx;
      final dy = w.end.dy - w.start.dy;
      return {
        'id': w.id,
        'title': 'Tembok',
        'desc': w.description,
        'type': 'Struktur',
        'isPath': false,
        'nav': null,
        'rotation': atan2(dy, dx), // Tambahkan rotation
      };
    } catch (_) {}
    return null;
  }
}
