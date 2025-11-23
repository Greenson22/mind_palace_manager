import 'package:flutter/material.dart';
import 'dart:math';
import 'plan_variables.dart';
import 'plan_view_mixin.dart';
import 'plan_state_mixin.dart';
import '../../data/plan_models.dart';
import '../plan_enums.dart';

// --- IMPORT MIXIN BARU ---
// Ganti import 'plan_selection_mixin.dart' dengan dua ini:
import 'plan_selection_core_mixin.dart';
import 'plan_transform_mixin.dart';

// --- UPDATE SYARAT MIXIN (ON CLAUSE) ---
// Ganti 'PlanSelectionMixin' dengan 'PlanSelectionCoreMixin' dan 'PlanTransformMixin'
mixin PlanInputMixin
    on
        PlanVariables,
        PlanViewMixin,
        PlanSelectionCoreMixin,
        PlanTransformMixin,
        PlanStateMixin {
  // ... (Sisa kode di bawah ini tetap sama, tidak perlu diubah) ...

  // Helper: Mencari Tembok Terdekat & Sudutnya
  Map<String, dynamic>? _getNearestWallInfo(Offset pos) {
    for (var wall in walls) {
      double dx = wall.end.dx - wall.start.dx;
      double dy = wall.end.dy - wall.start.dy;
      if (dx == 0 && dy == 0) continue;

      // Proyeksi titik ke garis
      double t =
          ((pos.dx - wall.start.dx) * dx + (pos.dy - wall.start.dy) * dy) /
          (dx * dx + dy * dy);
      t = max(0, min(1, t)); // Clamp agar tetap di dalam segmen garis

      Offset closest = Offset(wall.start.dx + t * dx, wall.start.dy + t * dy);

      // Jika jarak < 20, anggap menempel (snap)
      if ((pos - closest).distance < 20.0) {
        return {
          'pos': closest,
          'rotation': atan2(dy, dx), // Ambil sudut tembok
        };
      }
    }
    return null;
  }

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
        moveSelectedItem(delta); // Ini sekarang ada di PlanTransformMixin
        lastDragPos = targetPos;
      }
    } else if (activeTool == PlanTool.moveAll &&
        isDragging &&
        lastDragPos != null) {
      final delta = localPos - lastDragPos!;
      moveAllContent(delta); // Ini juga di PlanTransformMixin
      lastDragPos = localPos;
    } else if (activeTool == PlanTool.wall && tempStart != null) {
      Offset pos = getSmartSnapPoint(localPos);
      // Fitur Lurus Otomatis (Ortho)
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
      final newShape = PlanShape(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rect: Rect.fromPoints(tempStart!, tempEnd!),
        type: selectedShapeType,
        color: activeColor,
        isFilled: shapeFilled,
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

    if (activeTool == PlanTool.door || activeTool == PlanTool.window) {
      final wallInfo = _getNearestWallInfo(localPos);
      Offset finalPos = localPos;
      double finalRotation = 0.0;

      if (wallInfo != null) {
        finalPos = wallInfo['pos'];
        finalRotation = wallInfo['rotation'];
      } else if (enableSnap) {
        finalPos = snapToGrid(localPos);
      }

      final newPortal = PlanPortal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: finalPos,
        rotation: finalRotation,
        type: activeTool == PlanTool.door
            ? PlanPortalType.door
            : PlanPortalType.window,
        width: 40.0,
        color: activeColor,
      );

      updateActiveFloor(portals: [...portals, newPortal]);
      saveState();
      activeTool = PlanTool.select;
      selectedId = newPortal.id;
      notifyListeners();
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
