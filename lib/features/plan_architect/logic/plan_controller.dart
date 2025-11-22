// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert'; // Untuk Deep Copy (Undo/Redo)
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/plan_models.dart';

// Tambahkan 'eraser' dan 'freehand' ke Enum
enum PlanTool { select, wall, object, eraser, freehand }

class PlanController extends ChangeNotifier {
  List<Wall> walls = [];
  List<PlanObject> objects = [];
  List<PlanPath> paths = []; // List untuk gambar interior manual

  PlanTool activeTool = PlanTool.select;

  // State Sementara
  Offset? tempStart;
  Offset? tempEnd;

  // State Freehand (Menggambar)
  List<Offset> currentPathPoints = [];

  // State Object
  IconData? selectedObjectIcon;
  String selectedObjectName = "Furniture";

  // State Seleksi
  String? selectedId;
  bool isObjectSelected = false;

  // --- UNDO / REDO SYSTEM ---
  final List<String> _history = [];
  int _historyIndex = -1;

  PlanController() {
    _saveState(); // Simpan state awal kosong
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  // Menyimpan snapshot kondisi saat ini ke history
  void _saveState() {
    // Hapus history masa depan jika kita melakukan aksi baru setelah undo
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // Serialisasi semua data ke JSON string (Deep Copy paling aman)
    final state = jsonEncode({
      'walls': walls.map((e) => e.toJson()).toList(),
      'objects': objects.map((e) => e.toJson()).toList(),
      'paths': paths.map((e) => e.toJson()).toList(),
    });

    _history.add(state);
    _historyIndex++;

    // Batasi history agar tidak memakan memori (misal max 30 langkah)
    if (_history.length > 30) {
      _history.removeAt(0);
      _historyIndex--;
    }

    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _historyIndex--;
    _loadState(_history[_historyIndex]);
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex++;
    _loadState(_history[_historyIndex]);
  }

  void _loadState(String stateJson) {
    final data = jsonDecode(stateJson);
    walls = (data['walls'] as List).map((e) => Wall.fromJson(e)).toList();
    objects = (data['objects'] as List)
        .map((e) => PlanObject.fromJson(e))
        .toList();
    paths = (data['paths'] as List).map((e) => PlanPath.fromJson(e)).toList();
    selectedId = null; // Reset seleksi
    notifyListeners();
  }

  // --- TOOL ACTIONS ---

  void setTool(PlanTool tool) {
    activeTool = tool;
    selectedId = null;
    notifyListeners();
  }

  void selectObjectIcon(IconData icon, String name) {
    selectedObjectIcon = icon;
    selectedObjectName = name;
    setTool(PlanTool.object);
  }

  // --- INPUT HANDLING ---

  void onPanStart(Offset localPos) {
    if (activeTool == PlanTool.wall) {
      tempStart = localPos;
      tempEnd = localPos;
    } else if (activeTool == PlanTool.freehand) {
      // Mulai garis baru
      currentPathPoints = [localPos];
    }
    notifyListeners();
  }

  void onPanUpdate(Offset localPos) {
    if (activeTool == PlanTool.wall && tempStart != null) {
      tempEnd = localPos;
    } else if (activeTool == PlanTool.freehand) {
      // Tambahkan titik ke garis
      currentPathPoints.add(localPos);
    }
    notifyListeners();
  }

  void onPanEnd() {
    if (activeTool == PlanTool.wall && tempStart != null && tempEnd != null) {
      if ((tempStart! - tempEnd!).distance > 5) {
        walls.add(
          Wall(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            start: tempStart!,
            end: tempEnd!,
            description: "Tembok Baru",
          ),
        );
        _saveState(); // Simpan history
      }
      tempStart = null;
      tempEnd = null;
    } else if (activeTool == PlanTool.freehand &&
        currentPathPoints.isNotEmpty) {
      // Simpan gambar manual
      paths.add(
        PlanPath(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          points: List.from(currentPathPoints),
          color: Colors.brown, // Warna default interior kayu
        ),
      );
      currentPathPoints = [];
      _saveState(); // Simpan history
    }
    notifyListeners();
  }

  void onTapUp(Offset localPos) {
    if (activeTool == PlanTool.object && selectedObjectIcon != null) {
      objects.add(
        PlanObject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: localPos,
          name: selectedObjectName,
          description: "Deskripsi $selectedObjectName...",
          iconCodePoint: selectedObjectIcon!.codePoint,
        ),
      );
      _saveState(); // Simpan history
    } else if (activeTool == PlanTool.select) {
      _handleSelection(localPos);
    } else if (activeTool == PlanTool.eraser) {
      _handleEraser(localPos);
    }
  }

  // --- LOGIKA PENGHAPUS (TOGGLE DELETE) ---
  void _handleEraser(Offset pos) {
    bool deleted = false;

    // Cek Objek
    final objIndex = objects.lastIndexWhere(
      (obj) => (obj.position - pos).distance < 30.0,
    );
    if (objIndex != -1) {
      objects.removeAt(objIndex);
      deleted = true;
    }

    // Cek Tembok (jika belum hapus objek)
    if (!deleted) {
      final wallIndex = walls.indexWhere(
        (w) => _isPointNearLine(pos, w.start, w.end, 15.0),
      );
      if (wallIndex != -1) {
        walls.removeAt(wallIndex);
        deleted = true;
      }
    }

    // Cek Gambar Manual (Paths) - Hit test sederhana (titik awal/akhir atau bounding box)
    // Untuk simplifikasi, kita cek jarak ke titik mana saja di path
    if (!deleted) {
      final pathIndex = paths.lastIndexWhere((path) {
        return path.points.any((p) => (p - pos).distance < 15.0);
      });
      if (pathIndex != -1) {
        paths.removeAt(pathIndex);
        deleted = true;
      }
    }

    if (deleted) {
      _saveState();
    }
  }

  // --- LOGIKA SELEKSI ---
  void _handleSelection(Offset pos) {
    selectedId = null;
    isObjectSelected = false;

    for (var obj in objects.reversed) {
      if ((obj.position - pos).distance < 25.0) {
        selectedId = obj.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }

    for (var wall in walls) {
      if (_isPointNearLine(pos, wall.start, wall.end, 15.0)) {
        selectedId = wall.id;
        isObjectSelected = false;
        notifyListeners();
        return;
      }
    }
    notifyListeners();
  }

  bool _isPointNearLine(Offset p, Offset a, Offset b, double threshold) {
    double dx = b.dx - a.dx;
    double dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return false;
    double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);
    t = max(0, min(1, t));
    Offset closest = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - closest).distance < threshold;
  }

  // --- UPDATE & DELETE (Dari Dialog Edit) ---

  void updateDescription(String newDesc, {String? newName}) {
    if (selectedId == null) return;
    if (isObjectSelected) {
      final idx = objects.indexWhere((o) => o.id == selectedId);
      if (idx != -1) {
        objects[idx] = objects[idx].copyWith(
          description: newDesc,
          name: newName,
        );
        _saveState();
      }
    } else {
      final idx = walls.indexWhere((w) => w.id == selectedId);
      if (idx != -1) {
        walls[idx] = walls[idx].copyWith(description: newDesc);
        _saveState();
      }
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
    _saveState();
  }

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
}
