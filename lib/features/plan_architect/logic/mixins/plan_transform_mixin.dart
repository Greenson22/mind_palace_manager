import 'dart:math';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';
import '../plan_enums.dart';

mixin PlanTransformMixin on PlanVariables, PlanStateMixin {
  void nudgeSelection(Offset delta) {
    moveSelectedItem(delta);
    notifyListeners();
  }

  void moveSelectedItem(Offset delta) {
    // Multi Select Move
    if (isMultiSelectMode) {
      bool changed = false;
      // Clone lists
      List<PlanShape> newShapes = List.from(shapes);
      List<PlanObject> newObjects = List.from(objects);
      List<Wall> newWalls = List.from(walls);
      List<PlanLabel> newLabels = List.from(labels);
      List<PlanPath> newPaths = List.from(paths);
      List<PlanGroup> newGroups = List.from(groups);
      List<PlanPortal> newPortals = List.from(portals);

      for (var id in multiSelectedIds) {
        // Cek dan update jika id ditemukan di masing-masing list
        int idx;

        if ((idx = newShapes.indexWhere((x) => x.id == id)) != -1) {
          newShapes[idx] = newShapes[idx].moveBy(delta);
          changed = true;
        } else if ((idx = newObjects.indexWhere((x) => x.id == id)) != -1) {
          newObjects[idx] = newObjects[idx].moveBy(delta);
          changed = true;
        } else if ((idx = newWalls.indexWhere((x) => x.id == id)) != -1) {
          newWalls[idx] = newWalls[idx].moveBy(delta);
          changed = true;
        } else if ((idx = newLabels.indexWhere((x) => x.id == id)) != -1) {
          newLabels[idx] = newLabels[idx].moveBy(delta);
          changed = true;
        } else if ((idx = newPaths.indexWhere((x) => x.id == id)) != -1) {
          newPaths[idx] = newPaths[idx].moveBy(delta);
          changed = true;
        } else if ((idx = newGroups.indexWhere((x) => x.id == id)) != -1) {
          newGroups[idx] = newGroups[idx].moveBy(delta);
          changed = true;
        } else if ((idx = newPortals.indexWhere((x) => x.id == id)) != -1) {
          newPortals[idx] = newPortals[idx].moveBy(delta);
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

    // Cek satu per satu
    int idx;
    if ((idx = portals.indexWhere((p) => p.id == selectedId)) != -1) {
      var newPortals = List<PlanPortal>.from(portals);
      newPortals[idx] = newPortals[idx].moveBy(delta);
      updateActiveFloor(portals: newPortals);
    } else if ((idx = groups.indexWhere((g) => g.id == selectedId)) != -1) {
      var newGroups = List<PlanGroup>.from(groups);
      newGroups[idx] = newGroups[idx].moveBy(delta);
      updateActiveFloor(groups: newGroups);
    } else if ((idx = shapes.indexWhere((s) => s.id == selectedId)) != -1) {
      var newShapes = List<PlanShape>.from(shapes);
      newShapes[idx] = newShapes[idx].moveBy(delta);
      updateActiveFloor(shapes: newShapes);
    } else if ((idx = objects.indexWhere((o) => o.id == selectedId)) != -1) {
      var newObjects = List<PlanObject>.from(objects);
      newObjects[idx] = newObjects[idx].moveBy(delta);
      updateActiveFloor(objects: newObjects);
    } else if ((idx = walls.indexWhere((w) => w.id == selectedId)) != -1) {
      var newWalls = List<Wall>.from(walls);
      newWalls[idx] = newWalls[idx].moveBy(delta);
      updateActiveFloor(walls: newWalls);
    } else if ((idx = labels.indexWhere((l) => l.id == selectedId)) != -1) {
      var newLabels = List<PlanLabel>.from(labels);
      newLabels[idx] = newLabels[idx].moveBy(delta);
      updateActiveFloor(labels: newLabels);
    } else if ((idx = paths.indexWhere((p) => p.id == selectedId)) != -1) {
      var newPaths = List<PlanPath>.from(paths);
      newPaths[idx] = newPaths[idx].moveBy(delta);
      updateActiveFloor(paths: newPaths);
    }
  }

  void moveAllContent(Offset delta) {
    updateActiveFloor(
      walls: walls.map((w) => w.moveBy(delta)).toList(),
      objects: objects.map((o) => o.moveBy(delta)).toList(),
      paths: paths.map((p) => p.moveBy(delta)).toList(),
      labels: labels.map((l) => l.moveBy(delta)).toList(),
      shapes: shapes.map((s) => s.moveBy(delta)).toList(),
      groups: groups.map((g) => g.moveBy(delta)).toList(),
      portals: portals.map((p) => p.moveBy(delta)).toList(),
    );
  }

  void rotateSelected() {
    if (selectedId == null) return;

    int idx;
    // 1. Rotasi Group
    if ((idx = groups.indexWhere((g) => g.id == selectedId)) != -1) {
      var newGroups = List<PlanGroup>.from(groups);
      newGroups[idx] = newGroups[idx].copyWith(
        rotation: newGroups[idx].rotation + (pi / 2),
      );
      updateActiveFloor(groups: newGroups);
      saveState();
      return;
    }
    // 2. Rotasi Object
    if ((idx = objects.indexWhere((o) => o.id == selectedId)) != -1) {
      var newObjs = List<PlanObject>.from(objects);
      newObjs[idx] = newObjs[idx].copyWith(
        rotation: newObjs[idx].rotation + (pi / 2),
      );
      updateActiveFloor(objects: newObjs);
      saveState();
      return;
    }
    // 3. Rotasi Shape
    if ((idx = shapes.indexWhere((s) => s.id == selectedId)) != -1) {
      var newShapes = List<PlanShape>.from(shapes);
      newShapes[idx] = newShapes[idx].copyWith(
        rotation: newShapes[idx].rotation + (pi / 2),
      );
      updateActiveFloor(shapes: newShapes);
      saveState();
      return;
    }
    // 4. Rotasi Portal
    if ((idx = portals.indexWhere((p) => p.id == selectedId)) != -1) {
      var newPortals = List<PlanPortal>.from(portals);
      newPortals[idx] = newPortals[idx].copyWith(
        rotation: newPortals[idx].rotation + (pi / 4),
      );
      updateActiveFloor(portals: newPortals);
      saveState();
      return;
    }
    // 5. Rotasi Wall
    if ((idx = walls.indexWhere((w) => w.id == selectedId)) != -1) {
      var newWalls = List<Wall>.from(walls);
      final w = newWalls[idx];
      final center = (w.start + w.end) / 2;
      Offset rotatePoint(Offset p, Offset c) {
        final dx = p.dx - c.dx;
        final dy = p.dy - c.dy;
        return Offset(c.dx - dy, c.dy + dx);
      }

      newWalls[idx] = w.copyWith(
        start: rotatePoint(w.start, center),
        end: rotatePoint(w.end, center),
      );
      updateActiveFloor(walls: newWalls);
      saveState();
      return;
    }
    // 6. Rotasi Path
    if ((idx = paths.indexWhere((p) => p.id == selectedId)) != -1) {
      var newPaths = List<PlanPath>.from(paths);
      final p = newPaths[idx];
      // Hitung center bounding box
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
      newPaths[idx] = p.copyWith(points: newPoints);
      updateActiveFloor(paths: newPaths);
      saveState();
      return;
    }
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

    // Kumpulkan titik untuk bounding box
    for (var id in targetIds) {
      var w = walls.where((e) => e.id == id).firstOrNull;
      if (w != null) {
        includePoint(w.start.dx, w.start.dy);
        includePoint(w.end.dx, w.end.dy);
        continue;
      }

      var p = portals.where((e) => e.id == id).firstOrNull;
      if (p != null) {
        includePoint(p.position.dx, p.position.dy);
        continue;
      }

      var o = objects.where((e) => e.id == id).firstOrNull;
      if (o != null) {
        includePoint(o.position.dx, o.position.dy);
        continue;
      }

      var s = shapes.where((e) => e.id == id).firstOrNull;
      if (s != null) {
        includePoint(s.rect.center.dx, s.rect.center.dy);
        continue;
      }

      var g = groups.where((e) => e.id == id).firstOrNull;
      if (g != null) {
        includePoint(g.position.dx, g.position.dy);
        continue;
      }

      var path = paths.where((e) => e.id == id).firstOrNull;
      if (path != null) {
        for (var pt in path.points) includePoint(pt.dx, pt.dy);
        continue;
      }
    }

    if (count == 0) return;
    final pivot = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    Offset reflectPoint(Offset p) {
      if (horizontal) {
        return Offset(pivot.dx - (p.dx - pivot.dx), p.dy);
      } else {
        return Offset(p.dx, pivot.dy - (p.dy - pivot.dy));
      }
    }

    List<Wall> newWalls = List.from(walls);
    List<PlanPortal> newPortals = List.from(portals);
    List<PlanObject> newObjs = List.from(objects);
    List<PlanShape> newShapes = List.from(shapes);
    List<PlanGroup> newGroups = List.from(groups);
    List<PlanPath> newPaths = List.from(paths);
    bool changed = false;

    // 1. Flip Tembok
    for (int i = 0; i < newWalls.length; i++) {
      if (targetIds.contains(newWalls[i].id)) {
        newWalls[i] = newWalls[i].copyWith(
          start: reflectPoint(newWalls[i].start),
          end: reflectPoint(newWalls[i].end),
        );
        changed = true;
      }
    }
    // 2. Flip Path
    for (int i = 0; i < newPaths.length; i++) {
      if (targetIds.contains(newPaths[i].id)) {
        final flippedPoints = newPaths[i].points
            .map((pt) => reflectPoint(pt))
            .toList();
        newPaths[i] = newPaths[i].copyWith(points: flippedPoints);
        changed = true;
      }
    }

    // Helper untuk Item dengan Rotasi (Object, Portal, Group, Shape)
    void flipItem(dynamic item, Function(dynamic) updateCallback) {
      final newPos = reflectPoint(item.position);
      double newRot = item.rotation;
      bool newFlipX = item.flipX;

      // Toggle flipX internal
      newFlipX = !newFlipX;

      // Sesuaikan rotasi
      if (horizontal) {
        newRot = -newRot; // Flip H
      } else {
        newRot = pi - newRot; // Flip V
      }

      if (item is PlanShape) {
        final oldCenter = item.rect.center;
        final finalPos = reflectPoint(oldCenter);
        final offset = finalPos - oldCenter;
        updateCallback(
          item.copyWith(
            rect: item.rect.shift(offset),
            rotation: newRot,
            flipX: newFlipX,
          ),
        );
      } else {
        updateCallback(
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
}
