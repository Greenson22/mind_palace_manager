// lib/features/plan_architect/logic/mixins/plan_tool_mixin.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'plan_variables.dart';
import '../plan_enums.dart';
import '../../data/plan_models.dart';

mixin PlanToolMixin on PlanVariables {
  void setTool(PlanTool tool) {
    activeTool = tool;
    selectedId = null;
    isDragging = false;
    notifyListeners();
  }

  void setActiveColor(Color color) {
    activeColor = color;
    notifyListeners();
  }

  void setActiveStrokeWidth(double width) {
    activeStrokeWidth = width;
    notifyListeners();
  }

  void selectObjectIcon(IconData icon, String name) {
    selectedObjectIcon = icon;
    selectedObjectName = name;

    // Integrasi Fitur Recent
    AppSettings.addRecentInterior(name);

    setTool(PlanTool.object);
  }

  void selectShape(PlanShapeType type) {
    selectedShapeType = type;
    setTool(PlanTool.shape);
  }
}
