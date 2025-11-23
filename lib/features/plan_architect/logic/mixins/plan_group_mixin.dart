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

    // Kembalikan item ke posisi dunia (world space)
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
}
