// lib/features/plan_architect/logic/mixins/plan_state_mixin.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import '../../data/plan_models.dart';

mixin PlanStateMixin on PlanVariables {
  // Method abstract: Harus diimplementasikan oleh Mixin Image atau Controller
  void reloadImagesForActiveFloor();

  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < historyStack.length - 1;

  void initFloors() {
    if (floors.isEmpty) {
      floors.add(PlanFloor(id: 'floor_1', name: 'Lantai 1'));
    }
    hasUnsavedChanges = false;
    saveState(initial: true);
  }

  void addFloor() {
    final newId = 'floor_${floors.length + 1}';
    floors.add(PlanFloor(id: newId, name: 'Lantai ${floors.length + 1}'));
    activeFloorIndex = floors.length - 1;
    selectedId = null;
    saveState();
  }

  void removeActiveFloor() {
    if (floors.length <= 1) return;
    floors.removeAt(activeFloorIndex);
    if (activeFloorIndex >= floors.length) activeFloorIndex = floors.length - 1;
    selectedId = null;
    saveState();
  }

  void setActiveFloor(int index) {
    if (index >= 0 && index < floors.length) {
      activeFloorIndex = index;
      selectedId = null;
      notifyListeners();
      reloadImagesForActiveFloor();
    }
  }

  void renameActiveFloor(String newName) {
    floors[activeFloorIndex] = floors[activeFloorIndex].copyWith(name: newName);
    saveState();
  }

  void updateActiveFloor({
    List<Wall>? walls,
    List<PlanObject>? objects,
    List<PlanLabel>? labels,
    List<PlanPath>? paths,
    List<PlanShape>? shapes,
  }) {
    floors[activeFloorIndex] = activeFloor.copyWith(
      walls: walls,
      objects: objects,
      labels: labels,
      paths: paths,
      shapes: shapes,
    );
  }

  void saveState({bool initial = false}) {
    if (historyIndex < historyStack.length - 1) {
      historyStack.removeRange(historyIndex + 1, historyStack.length);
    }
    final state = jsonEncode({
      'floors': floors.map((f) => f.toJson()).toList(),
      'activeIdx': activeFloorIndex,
      'cc': canvasColor.value,
    });
    historyStack.add(state);
    historyIndex++;
    if (historyStack.length > 30) {
      historyStack.removeAt(0);
      historyIndex--;
    }

    if (!initial) {
      hasUnsavedChanges = true;
    }

    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    historyIndex--;
    loadState(historyStack[historyIndex]);
  }

  void redo() {
    if (!canRedo) return;
    historyIndex++;
    loadState(historyStack[historyIndex]);
  }

  void loadState(String stateJson) {
    final data = jsonDecode(stateJson);
    floors = (data['floors'] as List)
        .map((e) => PlanFloor.fromJson(e))
        .toList();
    activeFloorIndex = data['activeIdx'] ?? 0;
    if (data['cc'] != null) canvasColor = Color(data['cc']);
    if (activeFloorIndex >= floors.length) activeFloorIndex = 0;
    selectedId = null;
    notifyListeners();
    reloadImagesForActiveFloor();
  }

  void clearAll() {
    updateActiveFloor(
      walls: [],
      objects: [],
      paths: [],
      labels: [],
      shapes: [],
    );
    selectedId = null;
    saveState();
  }
}
