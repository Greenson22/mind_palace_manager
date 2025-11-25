// lib/features/plan_architect/logic/mixins/plan_edit_mixin.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart';
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
    String? referenceImage,
  }) {
    if (selectedId == null) return;

    int idx;
    if ((idx = groups.indexWhere((g) => g.id == selectedId)) != -1) {
      PlanGroup group = groups[idx];

      // --- LOGIKA BARU: RESIZE GROUP (SCALING) ---
      if (stroke != null) {
        final currentRect = group.getBounds();
        final currentWidth = currentRect.width;

        if (currentWidth > 0.1) {
          final scaleFactor = stroke / currentWidth;

          if (scaleFactor > 0.01 && scaleFactor < 100) {
            final newObjects = group.objects.map((o) {
              return o.copyWith(
                position: o.position * scaleFactor,
                size: o.size * scaleFactor,
              );
            }).toList();

            final newShapes = group.shapes.map((s) {
              final newRect = Rect.fromLTWH(
                s.rect.left * scaleFactor,
                s.rect.top * scaleFactor,
                s.rect.width * scaleFactor,
                s.rect.height * scaleFactor,
              );
              return s.copyWith(rect: newRect);
            }).toList();

            final newPaths = group.paths.map((p) {
              final newPoints = p.points.map((pt) => pt * scaleFactor).toList();
              return p.copyWith(
                points: newPoints,
                strokeWidth: p.strokeWidth * scaleFactor,
              );
            }).toList();

            final newWalls = group.walls.map((w) {
              return w.copyWith(
                start: w.start * scaleFactor,
                end: w.end * scaleFactor,
                thickness: w.thickness * scaleFactor,
              );
            }).toList();

            final newPortals = group.portals.map((p) {
              return p.copyWith(
                position: p.position * scaleFactor,
                width: p.width * scaleFactor,
              );
            }).toList();

            final newLabels = group.labels.map((l) {
              return l.copyWith(
                position: l.position * scaleFactor,
                fontSize: l.fontSize * scaleFactor,
              );
            }).toList();

            group = group.copyWith(
              objects: newObjects,
              shapes: newShapes,
              paths: newPaths,
              walls: newWalls,
              portals: newPortals,
              labels: newLabels,
            );
          }
        }
      }
      // -------------------------------------------

      updateActiveFloor(
        groups: List.from(groups)
          ..[idx] = group.copyWith(name: name, description: desc),
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
            referenceImage: referenceImage,
          ),
      );
    } else if ((idx = walls.indexWhere((w) => w.id == selectedId)) != -1) {
      updateActiveFloor(
        walls: List.from(walls)
          ..[idx] = walls[idx].copyWith(
            color: color,
            thickness: stroke,
            description: desc,
            referenceImage: referenceImage,
            navTargetFloorId: navTarget,
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
          ..[idx] = portals[idx].copyWith(
            color: color,
            width: stroke,
            description: desc,
            referenceImage: referenceImage,
            navTargetFloorId: navTarget,
          ),
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
            referenceImage: referenceImage,
          ),
      );
    }
    saveState();
  }

  // --- UPDATE: Simpan ke Global Library ---
  void saveCurrentSelectionToLibrary() {
    if (selectedId == null) return;

    dynamic itemToSave;
    String metaType = '';

    int pIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      itemToSave = paths[pIdx].copyWith(isSavedAsset: true);
      metaType = 'PlanPath';
    } else {
      int gIdx = groups.indexWhere((g) => g.id == selectedId);
      if (gIdx != -1) {
        itemToSave = groups[gIdx].copyWith(isSavedAsset: true);
        metaType = 'PlanGroup';
      }
    }

    if (itemToSave != null) {
      // Simpan ke list runtime
      savedCustomInteriors.add(itemToSave);

      // Simpan ke Persistent Storage
      final jsonStr = jsonEncode({
        'metaType': metaType,
        'data': itemToSave.toJson(),
      });
      AppSettings.addCustomAsset(jsonStr);

      notifyListeners();
    }
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

  void updateSelectedColor(Color color) =>
      updateSelectedAttribute(color: color);
  void updateSelectedStrokeWidth(double width) =>
      updateSelectedAttribute(stroke: width);

  void bringToFront() {
    if (selectedId == null) return;

    int gIdx = groups.indexWhere((g) => g.id == selectedId);
    if (gIdx != -1) {
      final item = groups[gIdx];
      final newList = List<PlanGroup>.from(groups)
        ..removeAt(gIdx)
        ..add(item);
      updateActiveFloor(groups: newList);
      saveState();
      return;
    }
    int oIdx = objects.indexWhere((o) => o.id == selectedId);
    if (oIdx != -1) {
      final item = objects[oIdx];
      final newList = List<PlanObject>.from(objects)
        ..removeAt(oIdx)
        ..add(item);
      updateActiveFloor(objects: newList);
      saveState();
      return;
    }
    int sIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (sIdx != -1) {
      final item = shapes[sIdx];
      final newList = List<PlanShape>.from(shapes)
        ..removeAt(sIdx)
        ..add(item);
      updateActiveFloor(shapes: newList);
      saveState();
      return;
    }
    int pIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      final item = paths[pIdx];
      final newList = List<PlanPath>.from(paths)
        ..removeAt(pIdx)
        ..add(item);
      updateActiveFloor(paths: newList);
      saveState();
      return;
    }
    int lIdx = labels.indexWhere((l) => l.id == selectedId);
    if (lIdx != -1) {
      final item = labels[lIdx];
      final newList = List<PlanLabel>.from(labels)
        ..removeAt(lIdx)
        ..add(item);
      updateActiveFloor(labels: newList);
      saveState();
      return;
    }
    int portIdx = portals.indexWhere((p) => p.id == selectedId);
    if (portIdx != -1) {
      final item = portals[portIdx];
      final newList = List<PlanPortal>.from(portals)
        ..removeAt(portIdx)
        ..add(item);
      updateActiveFloor(portals: newList);
      saveState();
      return;
    }
  }

  void sendToBack() {
    if (selectedId == null) return;

    int gIdx = groups.indexWhere((g) => g.id == selectedId);
    if (gIdx != -1) {
      final item = groups[gIdx];
      final newList = List<PlanGroup>.from(groups)
        ..removeAt(gIdx)
        ..insert(0, item);
      updateActiveFloor(groups: newList);
      saveState();
      return;
    }
    int oIdx = objects.indexWhere((o) => o.id == selectedId);
    if (oIdx != -1) {
      final item = objects[oIdx];
      final newList = List<PlanObject>.from(objects)
        ..removeAt(oIdx)
        ..insert(0, item);
      updateActiveFloor(objects: newList);
      saveState();
      return;
    }
    int sIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (sIdx != -1) {
      final item = shapes[sIdx];
      final newList = List<PlanShape>.from(shapes)
        ..removeAt(sIdx)
        ..insert(0, item);
      updateActiveFloor(shapes: newList);
      saveState();
      return;
    }
    int pIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      final item = paths[pIdx];
      final newList = List<PlanPath>.from(paths)
        ..removeAt(pIdx)
        ..insert(0, item);
      updateActiveFloor(paths: newList);
      saveState();
      return;
    }
    int lIdx = labels.indexWhere((l) => l.id == selectedId);
    if (lIdx != -1) {
      final item = labels[lIdx];
      final newList = List<PlanLabel>.from(labels)
        ..removeAt(lIdx)
        ..insert(0, item);
      updateActiveFloor(labels: newList);
      saveState();
      return;
    }
    int portIdx = portals.indexWhere((p) => p.id == selectedId);
    if (portIdx != -1) {
      final item = portals[portIdx];
      final newList = List<PlanPortal>.from(portals)
        ..removeAt(portIdx)
        ..insert(0, item);
      updateActiveFloor(portals: newList);
      saveState();
      return;
    }
  }

  void mergeSelectedWalls() {
    final selectedWallIds = <String>[];
    if (selectedId != null) selectedWallIds.add(selectedId!);
    selectedWallIds.addAll(multiSelectedIds);

    final targetWalls = walls
        .where((w) => selectedWallIds.contains(w.id))
        .toList();

    if (targetWalls.length != 2) return;

    final w1 = targetWalls[0];
    final w2 = targetWalls[1];

    if (_areWallsMergeable(w1, w2)) {
      final points = [w1.start, w1.end, w2.start, w2.end];
      double maxDist = -1.0;
      Offset pStart = points[0];
      Offset pEnd = points[0];

      for (int i = 0; i < points.length; i++) {
        for (int j = i + 1; j < points.length; j++) {
          final dist = (points[i] - points[j]).distance;
          if (dist > maxDist) {
            maxDist = dist;
            pStart = points[i];
            pEnd = points[j];
          }
        }
      }

      final newWall = w1.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        start: pStart,
        end: pEnd,
      );

      final newWallList = List<Wall>.from(walls)
        ..removeWhere((w) => w.id == w1.id || w.id == w2.id)
        ..add(newWall);

      updateActiveFloor(walls: newWallList);

      selectedId = newWall.id;
      multiSelectedIds.clear();
      isMultiSelectMode = false;

      saveState();
    }
  }

  bool _areWallsMergeable(Wall w1, Wall w2) {
    final v1 = w1.end - w1.start;
    final v2 = w2.end - w2.start;
    final crossProd = v1.dx * v2.dy - v1.dy * v2.dx;

    if (crossProd.abs() > 200) return false;

    const double touchThreshold = 20.0;
    bool touching = false;
    if ((w1.start - w2.start).distance < touchThreshold)
      touching = true;
    else if ((w1.start - w2.end).distance < touchThreshold)
      touching = true;
    else if ((w1.end - w2.start).distance < touchThreshold)
      touching = true;
    else if ((w1.end - w2.end).distance < touchThreshold)
      touching = true;

    return touching;
  }
}
