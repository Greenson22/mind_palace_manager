import 'dart:math';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';

mixin PlanEditMixin on PlanVariables, PlanStateMixin {
  void duplicateSelected() {
    if (selectedId == null) return;
    final offset = const Offset(20, 20);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    int idx;
    if ((idx = groups.indexWhere((g) => g.id == selectedId)) != -1) {
      updateActiveFloor(
        groups: [
          ...groups,
          groups[idx].copyWith(
            id: newId,
            position: groups[idx].position + offset,
          ),
        ],
      );
    } else if ((idx = objects.indexWhere((o) => o.id == selectedId)) != -1) {
      updateActiveFloor(
        objects: [
          ...objects,
          objects[idx].copyWith(
            id: newId,
            position: objects[idx].position + offset,
          ),
        ],
      );
    } else if ((idx = shapes.indexWhere((s) => s.id == selectedId)) != -1) {
      updateActiveFloor(
        shapes: [
          ...shapes,
          shapes[idx].copyWith(id: newId, rect: shapes[idx].rect.shift(offset)),
        ],
      );
    } else if ((idx = walls.indexWhere((w) => w.id == selectedId)) != -1) {
      updateActiveFloor(
        walls: [
          ...walls,
          walls[idx].copyWith(
            id: newId,
            start: walls[idx].start + offset,
            end: walls[idx].end + offset,
          ),
        ],
      );
    } else if ((idx = paths.indexWhere((p) => p.id == selectedId)) != -1) {
      updateActiveFloor(
        paths: [
          ...paths,
          paths[idx].moveBy(offset).copyWith(id: newId),
        ],
      );
    } else if ((idx = labels.indexWhere((l) => l.id == selectedId)) != -1) {
      updateActiveFloor(
        labels: [
          ...labels,
          labels[idx].moveBy(offset).copyWith(id: newId),
        ],
      );
    } else if ((idx = portals.indexWhere((p) => p.id == selectedId)) != -1) {
      updateActiveFloor(
        portals: [
          ...portals,
          portals[idx].copyWith(
            id: newId,
            position: portals[idx].position + offset,
          ),
        ],
      );
    } else {
      return;
    }

    selectedId = newId;
    saveState();
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

    int idx;
    if ((idx = groups.indexWhere((g) => g.id == selectedId)) != -1) {
      updateActiveFloor(
        groups: List.from(groups)..[idx] = groups[idx].copyWith(name: name),
      );
    } else if ((idx = objects.indexWhere((o) => o.id == selectedId)) != -1) {
      updateActiveFloor(
        objects: List.from(objects)
          ..[idx] = objects[idx].copyWith(
            color: color,
            description: desc,
            name: name,
            navTargetFloorId: navTarget,
            size: stroke,
          ),
      );
    } else if ((idx = walls.indexWhere((w) => w.id == selectedId)) != -1) {
      updateActiveFloor(
        walls: List.from(walls)
          ..[idx] = walls[idx].copyWith(
            color: color,
            thickness: stroke,
            description: desc,
          ),
      );
    } else if ((idx = paths.indexWhere((p) => p.id == selectedId)) != -1) {
      updateActiveFloor(
        paths: List.from(paths)
          ..[idx] = paths[idx].copyWith(
            color: color,
            strokeWidth: stroke,
            description: desc,
            name: name,
          ),
      );
    } else if ((idx = labels.indexWhere((l) => l.id == selectedId)) != -1) {
      updateActiveFloor(
        labels: List.from(labels)
          ..[idx] = labels[idx].copyWith(
            color: color,
            text: name,
            fontSize: stroke,
          ),
      );
    } else if ((idx = portals.indexWhere((p) => p.id == selectedId)) != -1) {
      updateActiveFloor(
        portals: List.from(portals)
          ..[idx] = portals[idx].copyWith(color: color, width: stroke),
      );
    } else if ((idx = shapes.indexWhere((s) => s.id == selectedId)) != -1) {
      PlanShape oldShape = shapes[idx];
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
      updateActiveFloor(
        shapes: List.from(shapes)
          ..[idx] = oldShape.copyWith(
            color: color,
            description: desc,
            name: name,
            rect: stroke != null ? newRect : null,
            isFilled: isFilled,
          ),
      );
    }
    saveState();
  }

  void updateSelectedWallLength(double newLengthInMeters) {
    if (selectedId == null) return;
    int idx = walls.indexWhere((w) => w.id == selectedId);
    if (idx != -1) {
      final oldWall = walls[idx];
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
      updateActiveFloor(
        walls: List.from(walls)..[idx] = oldWall.copyWith(end: newEnd),
      );
      saveState();
    }
  }

  void saveCurrentSelectionToLibrary() {
    if (selectedId == null) return;
    int idx;
    if ((idx = paths.indexWhere((p) => p.id == selectedId)) != -1) {
      savedCustomInteriors.add(paths[idx].copyWith(isSavedAsset: true));
      notifyListeners();
    } else if ((idx = groups.indexWhere((g) => g.id == selectedId)) != -1) {
      savedCustomInteriors.add(groups[idx].copyWith(isSavedAsset: true));
      notifyListeners();
    }
  }

  void updateSelectedColor(Color color) =>
      updateSelectedAttribute(color: color);
  void updateSelectedStrokeWidth(double width) =>
      updateSelectedAttribute(stroke: width);

  void bringToFront() {
    // Implementasi sederhana untuk demo: (Pindahkan ke akhir list)
    if (selectedId == null) return;
    // ... (Logika reorder list - opsional)
  }

  void sendToBack() {
    // ... (Logika reorder list - opsional)
  }
}
