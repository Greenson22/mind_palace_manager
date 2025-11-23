// lib/features/plan_architect/logic/mixins/plan_selection_mixin.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';

mixin PlanSelectionMixin on PlanVariables, PlanStateMixin {
  void handleSelection(Offset pos) {
    selectedId = null;
    isObjectSelected = false;
    for (var lbl in labels.reversed) {
      if ((lbl.position - pos).distance < 20.0) {
        selectedId = lbl.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    for (var obj in objects.reversed) {
      if ((obj.position - pos).distance < 25.0) {
        selectedId = obj.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    for (var shp in shapes.reversed) {
      if (shp.rect.contains(pos)) {
        selectedId = shp.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    for (var path in paths.reversed) {
      if (isPointNearPath(pos, path)) {
        selectedId = path.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    for (var wall in walls) {
      if (isPointNearLine(pos, wall.start, wall.end, 15.0)) {
        selectedId = wall.id;
        isObjectSelected = false;
        notifyListeners();
        return;
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
      if (isPointNearLine(p, path.points[i], path.points[i + 1], 10.0))
        return true;
    }
    return false;
  }

  void deleteSelected() {
    if (selectedId == null) return;
    updateActiveFloor(
      shapes: List.from(shapes)..removeWhere((s) => s.id == selectedId),
      labels: List.from(labels)..removeWhere((l) => l.id == selectedId),
      objects: List.from(objects)..removeWhere((o) => o.id == selectedId),
      paths: List.from(paths)..removeWhere((p) => p.id == selectedId),
      walls: List.from(walls)..removeWhere((w) => w.id == selectedId),
    );
    selectedId = null;
    saveState();
  }

  void moveSelectedItem(Offset delta) {
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

    updateActiveFloor(
      walls: newWalls,
      objects: newObjects,
      paths: newPaths,
      labels: newLabels,
      shapes: newShapes,
    );
  }

  void duplicateSelected() {
    if (selectedId == null) return;
    final offset = const Offset(20, 20);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

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

    selectedId = newId;
    saveState();
  }

  void rotateSelected() {
    if (selectedId == null) return;
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
  }

  void updateSelectedAttribute({
    Color? color,
    double? stroke,
    String? desc,
    String? name,
    String? navTarget,
  }) {
    if (selectedId == null) return;

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
      );
      updateActiveFloor(shapes: newShapes);
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
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes.add(newShapes.removeAt(shpIdx));
      updateActiveFloor(shapes: newShapes);
      saveState();
      return;
    }
    List<PlanObject> newObjs = List.from(objects);
    final objIdx = newObjs.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjs.add(newObjs.removeAt(objIdx));
      updateActiveFloor(objects: newObjs);
      saveState();
      return;
    }
  }

  void sendToBack() {
    if (selectedId == null) return;
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes.insert(0, newShapes.removeAt(shpIdx));
      updateActiveFloor(shapes: newShapes);
      saveState();
      return;
    }
    List<PlanObject> newObjs = List.from(objects);
    final objIdx = newObjs.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjs.insert(0, newObjs.removeAt(objIdx));
      updateActiveFloor(objects: newObjs);
      saveState();
      return;
    }
  }

  void saveCurrentSelectionToLibrary() {
    if (selectedId == null) return;
    final pathIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pathIdx != -1) {
      savedCustomInteriors.add(paths[pathIdx].copyWith(isSavedAsset: true));
      notifyListeners();
    }
  }

  Map<String, dynamic>? getSelectedItemData() {
    if (selectedId == null) return null;
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
