import 'dart:math';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';

mixin PlanGroupMixin on PlanVariables, PlanStateMixin {
  void createGroupFromSelection() {
    if (multiSelectedIds.isEmpty && selectedId == null) return;
    final idsToGroup = isMultiSelectMode
        ? multiSelectedIds.toList()
        : [selectedId!];
    if (idsToGroup.isEmpty) return;

    // Filter objek
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
    // --- TAMBAHAN: Filter Tembok dan Portal ---
    List<Wall> selWalls = walls
        .where((e) => idsToGroup.contains(e.id))
        .toList();
    List<PlanPortal> selPortals = portals
        .where((e) => idsToGroup.contains(e.id))
        .toList();

    if (selObjects.isEmpty &&
        selShapes.isEmpty &&
        selPaths.isEmpty &&
        selLabels.isEmpty &&
        selWalls.isEmpty &&
        selPortals.isEmpty) {
      return;
    }

    double sumX = 0, sumY = 0;
    int count = 0;

    // Hitung titik tengah (Centroid)
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
    for (var w in selWalls) {
      // Gunakan titik tengah tembok
      final center = (w.start + w.end) / 2;
      sumX += center.dx;
      sumY += center.dy;
      count++;
    }
    for (var p in selPortals) {
      sumX += p.position.dx;
      sumY += p.position.dy;
      count++;
    }

    if (count == 0) return;
    final groupCenter = Offset(sumX / count, sumY / count);

    // Pindahkan item relatif terhadap groupCenter
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

    final newWalls = selWalls.map((w) {
      return w.copyWith(start: w.start - groupCenter, end: w.end - groupCenter);
    }).toList();

    final newPortals = selPortals.map((p) {
      return p.copyWith(position: p.position - groupCenter);
    }).toList();

    final newGroup = PlanGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: groupCenter,
      objects: newObjects,
      shapes: newShapes,
      paths: newPaths,
      labels: newLabels,
      walls: newWalls, // MASUKKAN KE GROUP
      portals: newPortals, // MASUKKAN KE GROUP
      name: "Grup Baru",
    );

    updateActiveFloor(
      objects: objects.where((e) => !idsToGroup.contains(e.id)).toList(),
      shapes: shapes.where((e) => !idsToGroup.contains(e.id)).toList(),
      paths: paths.where((e) => !idsToGroup.contains(e.id)).toList(),
      labels: labels.where((e) => !idsToGroup.contains(e.id)).toList(),
      walls: walls
          .where((e) => !idsToGroup.contains(e.id))
          .toList(), // HAPUS DARI LANTAI
      portals: portals
          .where((e) => !idsToGroup.contains(e.id))
          .toList(), // HAPUS DARI LANTAI
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

    // Helper Rotasi
    Offset rotatePoint(Offset p, double angle) {
      if (angle == 0) return p;
      double cosA = cos(angle);
      double sinA = sin(angle);
      return Offset(p.dx * cosA - p.dy * sinA, p.dx * sinA + p.dy * cosA);
    }

    // Kembalikan item ke posisi dunia (world space) + Rotasi Grup
    final restoredObjects = group.objects.map((e) {
      final rotatedPos = rotatePoint(e.position, group.rotation);
      return e.copyWith(
        position: rotatedPos + group.position,
        rotation: e.rotation + group.rotation, // Tambahkan rotasi grup
      );
    }).toList();

    final restoredLabels = group.labels.map((e) {
      final rotatedPos = rotatePoint(e.position, group.rotation);
      return e.copyWith(position: rotatedPos + group.position);
    }).toList();

    final restoredShapes = group.shapes.map((e) {
      // Shape: Rect center harus diputar
      final center = e.rect.center;
      final rotatedCenter = rotatePoint(center, group.rotation);
      final finalCenter = rotatedCenter + group.position;
      final diff = finalCenter - center;

      return e.copyWith(
        rect: e.rect.shift(diff),
        rotation: e.rotation + group.rotation,
      );
    }).toList();

    final restoredPaths = group.paths.map((e) {
      final newPoints = e.points.map((pt) {
        return rotatePoint(pt, group.rotation) + group.position;
      }).toList();
      return e.copyWith(points: newPoints);
    }).toList();

    final restoredWalls = group.walls.map((w) {
      return w.copyWith(
        start: rotatePoint(w.start, group.rotation) + group.position,
        end: rotatePoint(w.end, group.rotation) + group.position,
      );
    }).toList();

    final restoredPortals = group.portals.map((p) {
      final rotatedPos = rotatePoint(p.position, group.rotation);
      return p.copyWith(
        position: rotatedPos + group.position,
        rotation: p.rotation + group.rotation,
      );
    }).toList();

    List<PlanGroup> newGroups = List.from(groups)..removeAt(grpIdx);
    updateActiveFloor(
      groups: newGroups,
      objects: [...objects, ...restoredObjects],
      shapes: [...shapes, ...restoredShapes],
      paths: [...paths, ...restoredPaths],
      labels: [...labels, ...restoredLabels],
      walls: [...walls, ...restoredWalls], // KEMBALIKAN KE LANTAI
      portals: [...portals, ...restoredPortals], // KEMBALIKAN KE LANTAI
    );
    selectedId = null;
    saveState();
  }
}
