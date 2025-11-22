// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/plan_models.dart';

enum PlanTool { select, wall, object, eraser, freehand }

class PlanController extends ChangeNotifier {
  List<Wall> walls = [];
  List<PlanObject> objects = [];
  List<PlanPath> paths = [];
  List<PlanPath> savedCustomInteriors = [];

  bool enableSnap = true;
  final double gridSize = 20.0;

  PlanTool activeTool = PlanTool.select;

  // State Menggambar
  Offset? tempStart;
  Offset? tempEnd;
  List<Offset> currentPathPoints = [];

  // State Move (Geser)
  bool isDragging = false;
  Offset? lastDragPos;

  // State Seleksi
  IconData? selectedObjectIcon;
  String selectedObjectName = "Furniture";
  String? selectedId;
  bool isObjectSelected = false;

  // History
  final List<String> _history = [];
  int _historyIndex = -1;

  PlanController() {
    _saveState();
  }

  // ... (Undo/Redo Logic SAMA SEPERTI SEBELUMNYA) ...
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void _saveState() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    final state = jsonEncode({
      'walls': walls.map((e) => e.toJson()).toList(),
      'objects': objects.map((e) => e.toJson()).toList(),
      'paths': paths.map((e) => e.toJson()).toList(),
    });
    _history.add(state);
    _historyIndex++;
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
    selectedId = null;
    notifyListeners();
  }

  void setTool(PlanTool tool) {
    activeTool = tool;
    selectedId = null;
    isDragging = false;
    notifyListeners();
  }

  void selectObjectIcon(IconData icon, String name) {
    selectedObjectIcon = icon;
    selectedObjectName = name;
    setTool(PlanTool.object);
  }

  void toggleSnap() {
    enableSnap = !enableSnap;
    notifyListeners();
  }

  // --- LOGIKA SNAP (GRID & MAGNET) ---

  // Menggabungkan Snap Grid dan Magnet ke Tembok Lain
  Offset _getSmartSnapPoint(Offset rawPos) {
    // 1. Cek Magnet ke Ujung Tembok Lain (Join)
    for (var wall in walls) {
      if ((rawPos - wall.start).distance < 15.0) return wall.start;
      if ((rawPos - wall.end).distance < 15.0) return wall.end;
    }

    // 2. Jika tidak ada magnet, Snap ke Grid jika aktif
    if (enableSnap) {
      double x = (rawPos.dx / gridSize).round() * gridSize;
      double y = (rawPos.dy / gridSize).round() * gridSize;
      return Offset(x, y);
    }

    return rawPos;
  }

  // --- INPUT HANDLING ---

  void onPanStart(Offset localPos) {
    if (activeTool == PlanTool.select) {
      // Cek apakah klik pada item untuk mulai drag
      _handleSelection(localPos);
      if (selectedId != null) {
        isDragging = true;
        lastDragPos = localPos;
      }
    } else if (activeTool == PlanTool.wall) {
      Offset pos = _getSmartSnapPoint(localPos);
      tempStart = pos;
      tempEnd = pos;
    } else if (activeTool == PlanTool.freehand) {
      currentPathPoints = [localPos];
    }
    notifyListeners();
  }

  void onPanUpdate(Offset localPos) {
    if (activeTool == PlanTool.select &&
        isDragging &&
        selectedId != null &&
        lastDragPos != null) {
      // --- LOGIKA MOVE (PINDAH) ---
      final delta = localPos - lastDragPos!;

      if (isObjectSelected) {
        // Pindah Objek
        final objIdx = objects.indexWhere((o) => o.id == selectedId);
        if (objIdx != -1) {
          objects[objIdx] = objects[objIdx].moveBy(delta);
        } else {
          // Pindah Path
          final pathIdx = paths.indexWhere((p) => p.id == selectedId);
          if (pathIdx != -1) {
            paths[pathIdx] = paths[pathIdx].moveBy(delta);
          }
        }
      } else {
        // Pindah Tembok
        final wallIdx = walls.indexWhere((w) => w.id == selectedId);
        if (wallIdx != -1) {
          walls[wallIdx] = walls[wallIdx].moveBy(delta);
        }
      }
      lastDragPos = localPos; // Update posisi terakhir
    } else if (activeTool == PlanTool.wall && tempStart != null) {
      Offset pos = _getSmartSnapPoint(localPos);

      // Auto-straighten (Meluruskan garis otomatis)
      if ((pos.dx - tempStart!.dx).abs() < 10)
        pos = Offset(tempStart!.dx, pos.dy);
      if ((pos.dy - tempStart!.dy).abs() < 10)
        pos = Offset(pos.dx, tempStart!.dy);

      tempEnd = pos;
    } else if (activeTool == PlanTool.freehand) {
      currentPathPoints.add(localPos);
    }
    notifyListeners();
  }

  void onPanEnd() {
    if (activeTool == PlanTool.select && isDragging) {
      isDragging = false;
      lastDragPos = null;
      _saveState(); // Simpan posisi baru ke history
    } else if (activeTool == PlanTool.wall &&
        tempStart != null &&
        tempEnd != null) {
      if ((tempStart! - tempEnd!).distance > 5) {
        walls.add(
          Wall(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            start: tempStart!,
            end: tempEnd!,
            description: "Tembok Baru",
          ),
        );
        _saveState();
      }
      tempStart = null;
      tempEnd = null;
    } else if (activeTool == PlanTool.freehand &&
        currentPathPoints.isNotEmpty) {
      paths.add(
        PlanPath(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          points: List.from(currentPathPoints),
          name: "Interior Custom",
          description: "Deskripsi interior...",
        ),
      );
      currentPathPoints = [];
      _saveState();
    }
    notifyListeners();
  }

  void onTapUp(Offset localPos) {
    if (activeTool == PlanTool.object && selectedObjectIcon != null) {
      Offset pos = _getSmartSnapPoint(localPos);
      objects.add(
        PlanObject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: pos,
          name: selectedObjectName,
          description: "Deskripsi $selectedObjectName...",
          iconCodePoint: selectedObjectIcon!.codePoint,
        ),
      );
      _saveState();
    } else if (activeTool == PlanTool.select) {
      // Jika tap tanpa drag, hanya select (sudah dihandle di PanStart, tapi double check)
      if (!isDragging) _handleSelection(localPos);
    } else if (activeTool == PlanTool.eraser) {
      _handleEraser(localPos);
    }
  }

  // ... (Sisa metode: _handleSelection, _handleEraser, updateDescription, deleteSelected, Library Functions SAMA SEPERTI KODE SEBELUMNYA) ...
  // Saya sertakan _handleSelection agar lengkap

  void _handleSelection(Offset pos) {
    selectedId = null;
    isObjectSelected = false;

    // 1. Objek
    for (var obj in objects.reversed) {
      if ((obj.position - pos).distance < 25.0) {
        selectedId = obj.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    // 2. Path
    for (var path in paths.reversed) {
      if (_isPointNearPath(pos, path)) {
        selectedId = path.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    // 3. Tembok
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

  bool _isPointNearPath(Offset p, PlanPath path) {
    if (path.points.length < 2) return false;
    for (int i = 0; i < path.points.length - 1; i++) {
      if (_isPointNearLine(p, path.points[i], path.points[i + 1], 10.0))
        return true;
    }
    return false;
  }

  void _handleEraser(Offset pos) {
    bool deleted = false;
    final objIndex = objects.lastIndexWhere(
      (obj) => (obj.position - pos).distance < 30.0,
    );
    if (objIndex != -1) {
      objects.removeAt(objIndex);
      deleted = true;
    }
    if (!deleted) {
      final pathIndex = paths.lastIndexWhere(
        (path) => _isPointNearPath(pos, path),
      );
      if (pathIndex != -1) {
        paths.removeAt(pathIndex);
        deleted = true;
      }
    }
    if (!deleted) {
      final wallIndex = walls.indexWhere(
        (w) => _isPointNearLine(pos, w.start, w.end, 15.0),
      );
      if (wallIndex != -1) {
        walls.removeAt(wallIndex);
        deleted = true;
      }
    }
    if (deleted) _saveState();
  }

  void updateDescription(String newDesc, {String? newName}) {
    if (selectedId == null) return;
    final objIdx = objects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      objects[objIdx] = objects[objIdx].copyWith(
        description: newDesc,
        name: newName,
      );
      _saveState();
      return;
    }
    final pathIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pathIdx != -1) {
      paths[pathIdx] = paths[pathIdx].copyWith(
        description: newDesc,
        name: newName,
      );
      _saveState();
      return;
    }
    final wallIdx = walls.indexWhere((w) => w.id == selectedId);
    if (wallIdx != -1) {
      walls[wallIdx] = walls[wallIdx].copyWith(description: newDesc);
      _saveState();
      return;
    }
  }

  void deleteSelected() {
    if (selectedId == null) return;
    objects.removeWhere((o) => o.id == selectedId);
    paths.removeWhere((p) => p.id == selectedId);
    walls.removeWhere((w) => w.id == selectedId);
    selectedId = null;
    _saveState();
    notifyListeners();
  }

  Map<String, dynamic>? getSelectedItemData() {
    if (selectedId == null) return null;
    try {
      final obj = objects.firstWhere((o) => o.id == selectedId);
      return {
        'id': obj.id,
        'title': obj.name,
        'desc': obj.description,
        'type': 'Furniture',
        'isPath': false,
      };
    } catch (_) {}
    try {
      final path = paths.firstWhere((p) => p.id == selectedId);
      return {
        'id': path.id,
        'title': path.name,
        'desc': path.description,
        'type': 'Custom Interior',
        'isPath': true,
      };
    } catch (_) {}
    try {
      final wall = walls.firstWhere((w) => w.id == selectedId);
      return {
        'id': wall.id,
        'title': 'Tembok',
        'desc': wall.description,
        'type': 'Struktur',
        'isPath': false,
      };
    } catch (_) {}
    return null;
  }

  void saveCurrentSelectionToLibrary() {
    if (selectedId == null) return;
    final pathIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pathIdx != -1) {
      final savedCopy = paths[pathIdx].copyWith(isSavedAsset: true);
      savedCustomInteriors.add(savedCopy);
      notifyListeners();
    }
  }

  void placeSavedPath(PlanPath savedPath, Offset centerPos) {
    if (savedPath.points.isEmpty) return;
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
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

    paths.add(
      PlanPath(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: newPoints,
        name: savedPath.name,
        description: savedPath.description,
        color: savedPath.color,
      ),
    );
    _saveState();
    notifyListeners();
  }
}
