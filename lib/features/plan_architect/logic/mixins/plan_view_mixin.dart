// lib/features/plan_architect/logic/mixins/plan_view_mixin.dart
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import '../plan_enums.dart';

mixin PlanViewMixin on PlanVariables {
  void toggleViewMode() {
    isViewMode = !isViewMode;
    if (isViewMode) {
      selectedId = null;
      activeTool = PlanTool.select;
    }
    notifyListeners();
  }

  void setCanvasColor(Color color) {
    canvasColor = color;
    notifyListeners();
  }

  void toggleGridVisibility() {
    showGrid = !showGrid;
    notifyListeners();
  }

  void setGridSize(double size) {
    gridSize = size;
    notifyListeners();
  }

  void toggleLayer(String layer) {
    switch (layer) {
      case 'walls':
        layerWalls = !layerWalls;
        break;
      case 'objects':
        layerObjects = !layerObjects;
        break;
      case 'labels':
        layerLabels = !layerLabels;
        break;
      case 'dims':
        layerDims = !layerDims;
        break;
    }
    notifyListeners();
  }

  void zoomIn() {
    transformController.value = transformController.value.clone()..scale(1.2);
  }

  void zoomOut() {
    transformController.value = transformController.value.clone()..scale(0.8);
  }

  void resetZoom() {
    transformController.value = Matrix4.identity();
  }

  void toggleSnap() {
    enableSnap = !enableSnap;
    notifyListeners();
  }

  Offset snapToGrid(Offset pos) {
    double x = (pos.dx / gridSize).round() * gridSize;
    double y = (pos.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }

  Offset getSmartSnapPoint(Offset rawPos) {
    for (var wall in walls) {
      if ((rawPos - wall.start).distance < 15.0) return wall.start;
      if ((rawPos - wall.end).distance < 15.0) return wall.end;
    }
    if (enableSnap) return snapToGrid(rawPos);
    return rawPos;
  }
}
