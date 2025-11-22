// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/plan_models.dart';

enum PlanTool { select, wall, object }

class PlanController extends ChangeNotifier {
  List<Wall> walls = [];
  List<PlanObject> objects = [];

  PlanTool activeTool = PlanTool.select;

  // State Menggambar Tembok
  Offset? tempStart;
  Offset? tempEnd;

  // State Penempatan Objek
  IconData? selectedObjectIcon;
  String selectedObjectName = "Furniture";

  // Hit Testing (Seleksi)
  String? selectedId; // Bisa ID Wall atau ID Object
  bool isObjectSelected =
      false; // True jika yang dipilih objek, False jika tembok

  // --- ACTIONS ---

  void setTool(PlanTool tool) {
    activeTool = tool;
    selectedId = null; // Reset seleksi saat ganti alat
    notifyListeners();
  }

  void selectObjectIcon(IconData icon, String name) {
    selectedObjectIcon = icon;
    selectedObjectName = name;
    setTool(PlanTool.object);
  }

  // --- DRAWING LOGIC ---

  void onPanStart(Offset localPos) {
    if (activeTool == PlanTool.wall) {
      tempStart = localPos;
      tempEnd = localPos;
      notifyListeners();
    }
  }

  void onPanUpdate(Offset localPos) {
    if (activeTool == PlanTool.wall && tempStart != null) {
      tempEnd = localPos;
      notifyListeners();
    }
  }

  void onPanEnd() {
    if (activeTool == PlanTool.wall && tempStart != null && tempEnd != null) {
      // Minimal panjang tembok agar tidak sengaja titik
      if ((tempStart! - tempEnd!).distance > 5) {
        final newWall = Wall(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          start: tempStart!,
          end: tempEnd!,
          description: "Tembok Baru",
        );
        walls.add(newWall);
      }
      tempStart = null;
      tempEnd = null;
      notifyListeners();
    }
  }

  void onTapUp(Offset localPos) {
    if (activeTool == PlanTool.object && selectedObjectIcon != null) {
      // Tambah Objek
      final newObj = PlanObject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: localPos,
        name: selectedObjectName,
        description: "Deskripsi $selectedObjectName...",
        iconCodePoint: selectedObjectIcon!.codePoint,
      );
      objects.add(newObj);
      notifyListeners();
    } else if (activeTool == PlanTool.select) {
      _handleSelection(localPos);
    }
  }

  // --- HIT TEST LOGIC (Deteksi Ketukan) ---

  void _handleSelection(Offset pos) {
    selectedId = null;
    isObjectSelected = false;

    // 1. Cek Objek (Prioritas)
    for (var obj in objects.reversed) {
      if ((obj.position - pos).distance < 25.0) {
        // Radius hit 25
        selectedId = obj.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }

    // 2. Cek Tembok (Garis)
    for (var wall in walls) {
      if (_isPointNearLine(pos, wall.start, wall.end, 15.0)) {
        selectedId = wall.id;
        isObjectSelected = false; // Tembok
        notifyListeners();
        return;
      }
    }
    notifyListeners();
  }

  // Rumus matematika jarak titik ke segmen garis
  bool _isPointNearLine(Offset p, Offset a, Offset b, double threshold) {
    double dx = b.dx - a.dx;
    double dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return false;

    double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);

    // Batasi t antara 0 dan 1 (segmen garis, bukan garis tak hingga)
    t = max(0, min(1, t));

    Offset closest = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - closest).distance < threshold;
  }

  // --- UPDATE DATA ---

  void updateDescription(String newDesc, {String? newName}) {
    if (selectedId == null) return;

    if (isObjectSelected) {
      final idx = objects.indexWhere((o) => o.id == selectedId);
      if (idx != -1) {
        objects[idx] = objects[idx].copyWith(
          description: newDesc,
          name: newName,
        );
      }
    } else {
      final idx = walls.indexWhere((w) => w.id == selectedId);
      if (idx != -1) {
        walls[idx] = walls[idx].copyWith(description: newDesc);
      }
    }
    notifyListeners();
  }

  // Getter untuk data item yang sedang dipilih
  Map<String, String>? getSelectedItemData() {
    if (selectedId == null) return null;
    if (isObjectSelected) {
      final obj = objects.firstWhere((o) => o.id == selectedId);
      return {'title': obj.name, 'desc': obj.description, 'type': 'Interior'};
    } else {
      final wall = walls.firstWhere((w) => w.id == selectedId);
      return {'title': 'Tembok', 'desc': wall.description, 'type': 'Struktur'};
    }
  }

  void deleteSelected() {
    if (selectedId == null) return;
    if (isObjectSelected) {
      objects.removeWhere((o) => o.id == selectedId);
    } else {
      walls.removeWhere((w) => w.id == selectedId);
    }
    selectedId = null;
    notifyListeners();
  }
}
