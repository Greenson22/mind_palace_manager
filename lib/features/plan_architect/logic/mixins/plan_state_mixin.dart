import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'plan_variables.dart';
import '../../data/plan_models.dart';

mixin PlanStateMixin on PlanVariables {
  // Method abstract: Harus diimplementasikan oleh Mixin Image atau Controller
  void reloadImagesForActiveFloor();

  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < historyStack.length - 1;

  // --- FITUR BARU: LOAD & SAVE DARI FILE SPESIFIK ---
  Future<void> loadFromPath(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        loadState(content);
      } catch (e) {
        debugPrint("Gagal memuat denah: $e");
      }
    }
  }

  Future<void> saveToPath(String filePath) async {
    final file = File(filePath);
    // Simpan state aktif saat ini (floor 0)
    final state = jsonEncode({
      'floors': floors.map((f) => f.toJson()).toList(),
      'activeIdx': 0,
      'cc': canvasColor.value,
    });
    await file.writeAsString(state);
    hasUnsavedChanges = false;
    notifyListeners();
  }
  // --------------------------------------------------

  void initFloors() {
    // Pastikan hanya ada 1 lantai tetap
    if (floors.isEmpty) {
      floors.add(PlanFloor(id: 'main_plan', name: 'Denah Utama'));
    }
    // Paksa index ke 0
    activeFloorIndex = 0;
    hasUnsavedChanges = false;
    saveState(initial: true);
  }

  // Fungsi addFloor dan removeActiveFloor dihapus karena tidak lagi digunakan.

  void setActiveFloor(int index) {
    // Selalu paksa ke lantai utama (index 0)
    activeFloorIndex = 0;
    selectedId = null;
    notifyListeners();
    reloadImagesForActiveFloor();
  }

  void renameActiveFloor(String newName) {
    floors[0] = floors[0].copyWith(name: newName);
    saveState();
  }

  void updateActiveFloor({
    List<Wall>? walls,
    List<PlanObject>? objects,
    List<PlanLabel>? labels,
    List<PlanPath>? paths,
    List<PlanShape>? shapes,
    List<PlanGroup>? groups,
    List<PlanPortal>? portals,
  }) {
    // Selalu update floors[0]
    floors[0] = floors[0].copyWith(
      walls: walls ?? this.walls,
      objects: objects ?? this.objects,
      labels: labels ?? this.labels,
      paths: paths ?? this.paths,
      shapes: shapes ?? this.shapes,
      groups: groups ?? this.groups,
      portals: portals ?? this.portals,
    );
  }

  void saveState({bool initial = false}) {
    if (historyIndex < historyStack.length - 1) {
      historyStack.removeRange(historyIndex + 1, historyStack.length);
    }

    // Simpan state ke JSON, memaksa activeIdx ke 0
    final state = jsonEncode({
      'floors': floors.map((f) => f.toJson()).toList(),
      'activeIdx': 0,
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

    // Pastikan minimal ada 1 lantai jika data kosong
    if (floors.isEmpty) {
      floors.add(PlanFloor(id: 'main_plan', name: 'Denah Utama'));
    }

    activeFloorIndex = 0; // Selalu 0
    if (data['cc'] != null) canvasColor = Color(data['cc']);

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
      groups: [],
      portals: [],
    );
    selectedId = null;
    saveState();
  }
}
