// lib/features/plan_architect/logic/mixins/plan_view_mixin.dart
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import '../plan_enums.dart';
import 'package:mind_palace_manager/app_settings.dart'; // Import AppSettings

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
    // Simpan ke AppSettings
    AppSettings.savePlanCanvasColor(color.value);
    notifyListeners();
  }

  void toggleGridVisibility() {
    showGrid = !showGrid;
    // Simpan ke AppSettings
    AppSettings.savePlanShowGrid(showGrid);
    notifyListeners();
  }

  void toggleZoomButtonsVisibility() {
    showZoomButtons = !showZoomButtons;
    // Simpan ke AppSettings
    AppSettings.savePlanShowZoomButtons(showZoomButtons);
    notifyListeners();
  }

  void setGridSize(double size) {
    gridSize = size;
    // Simpan ke AppSettings
    AppSettings.savePlanGridSize(size);
    notifyListeners();
  }

  void toggleLayer(String layer) {
    switch (layer) {
      case 'walls':
        layerWalls = !layerWalls;
        AppSettings.savePlanLayerState('walls', layerWalls);
        break;
      case 'objects':
        layerObjects = !layerObjects;
        AppSettings.savePlanLayerState('objects', layerObjects);
        break;
      case 'labels':
        layerLabels = !layerLabels;
        AppSettings.savePlanLayerState('labels', layerLabels);
        break;
      case 'dims':
        layerDims = !layerDims;
        AppSettings.savePlanLayerState('dims', layerDims);
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
