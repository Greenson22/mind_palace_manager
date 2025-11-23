import 'package:flutter/material.dart';
import 'plan_variables.dart';
import 'plan_view_mixin.dart';
import 'plan_selection_mixin.dart';
import 'plan_state_mixin.dart';
import '../plan_enums.dart';
import '../../data/plan_models.dart';

mixin PlanInputMixin
    on PlanVariables, PlanViewMixin, PlanSelectionMixin, PlanStateMixin {
  // ... (onPanStart, onPanUpdate TETAP SAMA) ...
  void onPanStart(Offset localPos) {
    if (isViewMode) return;
    if (activeTool == PlanTool.hand) return;

    if (activeTool == PlanTool.select) {
      handleSelection(localPos);
      if (selectedId != null ||
          (isMultiSelectMode && multiSelectedIds.isNotEmpty)) {
        isDragging = true;
        lastDragPos = enableSnap ? snapToGrid(localPos) : localPos;
      }
    } else if (activeTool == PlanTool.moveAll) {
      isDragging = true;
      lastDragPos = localPos;
    } else if (activeTool == PlanTool.wall || activeTool == PlanTool.shape) {
      Offset pos = (activeTool == PlanTool.wall)
          ? getSmartSnapPoint(localPos)
          : localPos;
      tempStart = pos;
      tempEnd = pos;
    } else if (activeTool == PlanTool.freehand) {
      currentPathPoints = [localPos];
    }
    notifyListeners();
  }

  void onPanUpdate(Offset localPos) {
    if (isViewMode || activeTool == PlanTool.hand) return;

    if (activeTool == PlanTool.select && isDragging && lastDragPos != null) {
      Offset targetPos = enableSnap ? snapToGrid(localPos) : localPos;
      final delta = targetPos - lastDragPos!;
      if (delta.distanceSquared > 0) {
        moveSelectedItem(delta);
        lastDragPos = targetPos;
      }
    } else if (activeTool == PlanTool.moveAll &&
        isDragging &&
        lastDragPos != null) {
      final delta = localPos - lastDragPos!;
      moveAllContent(delta);
      lastDragPos = localPos;
    } else if (activeTool == PlanTool.wall && tempStart != null) {
      Offset pos = getSmartSnapPoint(localPos);
      if ((pos.dx - tempStart!.dx).abs() < 10)
        pos = Offset(tempStart!.dx, pos.dy);
      if ((pos.dy - tempStart!.dy).abs() < 10)
        pos = Offset(pos.dx, tempStart!.dy);
      tempEnd = pos;
    } else if (activeTool == PlanTool.shape && tempStart != null) {
      tempEnd = localPos;
    } else if (activeTool == PlanTool.freehand) {
      currentPathPoints.add(localPos);
    }
    notifyListeners();
  }

  void onPanEnd() {
    if (isViewMode || activeTool == PlanTool.hand) return;

    if (activeTool == PlanTool.select && isDragging) {
      isDragging = false;
      lastDragPos = null;
      saveState();
    } else if (activeTool == PlanTool.moveAll && isDragging) {
      isDragging = false;
      lastDragPos = null;
      saveState();
    } else if (activeTool == PlanTool.wall &&
        tempStart != null &&
        tempEnd != null) {
      if ((tempStart! - tempEnd!).distance > 5) {
        final newWall = Wall(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          start: tempStart!,
          end: tempEnd!,
          color: activeColor,
          thickness: activeStrokeWidth,
        );
        updateActiveFloor(walls: [...walls, newWall]);
        saveState();
      }
      tempStart = null;
      tempEnd = null;
    } else if (activeTool == PlanTool.shape &&
        tempStart != null &&
        tempEnd != null) {
      // --- UPDATE: Gunakan shapeFilled ---
      final newShape = PlanShape(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rect: Rect.fromPoints(tempStart!, tempEnd!),
        type: selectedShapeType,
        color: activeColor,
        isFilled: shapeFilled, // <-- Gunakan properti ini
      );

      updateActiveFloor(shapes: [...shapes, newShape]);
      saveState();
      tempStart = null;
      tempEnd = null;
    } else if (activeTool == PlanTool.freehand &&
        currentPathPoints.isNotEmpty) {
      final newPath = PlanPath(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: List.from(currentPathPoints),
        color: activeColor,
        strokeWidth: activeStrokeWidth,
      );
      updateActiveFloor(paths: [...paths, newPath]);
      currentPathPoints = [];
      saveState();
    }
    notifyListeners();
  }

  // ... (onTapUp, addLabel, placeSavedPath, placeSavedItem TETAP SAMA) ...
  void onTapUp(Offset localPos) {
    if (isViewMode) {
      handleSelection(localPos);
      if (selectedId != null) {
        try {
          final obj = objects.firstWhere((o) => o.id == selectedId);
          if (obj.navTargetFloorId != null) {
            final targetIdx = floors.indexWhere(
              (f) => f.id == obj.navTargetFloorId,
            );
            if (targetIdx != -1) setActiveFloor(targetIdx);
          }
        } catch (_) {}
      }
      return;
    }

    if (activeTool == PlanTool.hand || activeTool == PlanTool.moveAll) return;

    if (activeTool == PlanTool.object && selectedObjectIcon != null) {
      Offset pos = enableSnap ? snapToGrid(localPos) : localPos;
      final newObj = PlanObject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: pos,
        name: selectedObjectName,
        description: "...",
        iconCodePoint: selectedObjectIcon!.codePoint,
        color: activeColor,
        size: 14.0,
      );
      updateActiveFloor(objects: [...objects, newObj]);
      saveState();
    } else if (activeTool == PlanTool.select) {
      if (!isDragging) handleSelection(localPos);
    } else if (activeTool == PlanTool.eraser) {
      handleSelection(localPos);
      if (selectedId != null) deleteSelected();
    }
  }

  void addLabel(Offset pos, String text) {
    final newLbl = PlanLabel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: pos,
      text: text,
      color: activeColor,
      fontSize: 12.0,
    );
    updateActiveFloor(labels: [...labels, newLbl]);
    saveState();
  }

  void placeSavedPath(PlanPath savedPath, Offset centerPos) {
    if (savedPath.points.isEmpty) return;
    double minX = double.infinity,
        maxX = double.negativeInfinity,
        minY = double.infinity,
        maxY = double.negativeInfinity;
    for (var p in savedPath.points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final Offset oldCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final Offset offsetDiff = centerPos - oldCenter;
    final List<Offset> newPoints = savedPath.points
        .map((p) => p + offsetDiff)
        .toList();
    final newPath = savedPath.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: newPoints,
    );
    updateActiveFloor(paths: [...paths, newPath]);
    saveState();
    notifyListeners();
  }

  void placeSavedItem(dynamic savedItem, Offset centerPos) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    if (savedItem is PlanPath) {
      placeSavedPath(savedItem, centerPos);
    } else if (savedItem is PlanGroup) {
      final newGroup = savedItem.copyWith(id: newId, position: centerPos);
      updateActiveFloor(groups: [...groups, newGroup]);
      saveState();
      notifyListeners();
    }
  }
}
