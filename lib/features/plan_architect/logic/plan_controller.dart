// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/plan_models.dart';

enum PlanTool { select, wall, object, text, eraser, freehand, shape }

class PlanController extends ChangeNotifier {
  List<Wall> walls = [];
  List<PlanObject> objects = [];
  List<PlanPath> paths = [];
  List<PlanLabel> labels = [];
  List<PlanShape> shapes = [];
  List<PlanPath> savedCustomInteriors = [];

  bool enableSnap = true;
  final double gridSize = 20.0;
  PlanTool activeTool = PlanTool.select;

  // --- BARU: State Warna & Tebal Aktif (Default) ---
  Color activeColor = Colors.black;
  double activeStrokeWidth = 4.0;

  // State Drawing/Drag
  Offset? tempStart;
  Offset? tempEnd;
  List<Offset> currentPathPoints = [];
  bool isDragging = false;
  Offset? lastDragPos;

  // State Selection
  String? selectedId;
  bool isObjectSelected = false;

  // State New Item
  IconData? selectedObjectIcon;
  String selectedObjectName = "Furniture";
  PlanShapeType selectedShapeType = PlanShapeType.rectangle;

  // History
  final List<String> _history = [];
  int _historyIndex = -1;

  PlanController() {
    _saveState();
  }

  // ... (Undo/Redo, LoadState SAMA) ...
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  void _saveState() {
    if (_historyIndex < _history.length - 1)
      _history.removeRange(_historyIndex + 1, _history.length);
    final state = jsonEncode({
      'walls': walls.map((e) => e.toJson()).toList(),
      'objects': objects.map((e) => e.toJson()).toList(),
      'paths': paths.map((e) => e.toJson()).toList(),
      'labels': labels.map((e) => e.toJson()).toList(),
      'shapes': shapes.map((e) => e.toJson()).toList(),
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
    labels =
        (data['labels'] as List?)?.map((e) => PlanLabel.fromJson(e)).toList() ??
        [];
    shapes =
        (data['shapes'] as List?)?.map((e) => PlanShape.fromJson(e)).toList() ??
        [];
    selectedId = null;
    notifyListeners();
  }

  // --- SETTINGS ---
  void setActiveColor(Color color) {
    activeColor = color;
    notifyListeners();
  }

  void setActiveStrokeWidth(double width) {
    activeStrokeWidth = width;
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

  void selectShape(PlanShapeType type) {
    selectedShapeType = type;
    setTool(PlanTool.shape);
  }

  void toggleSnap() {
    enableSnap = !enableSnap;
    notifyListeners();
  }

  // --- UPDATE SELECTED ITEM ATTRIBUTES (BARU) ---
  void updateSelectedColor(Color color) {
    if (selectedId == null) return;
    final shpIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      shapes[shpIdx] = shapes[shpIdx].copyWith(color: color);
      _saveState();
      return;
    }
    final lblIdx = labels.indexWhere((l) => l.id == selectedId);
    if (lblIdx != -1) {
      labels[lblIdx] = labels[lblIdx].copyWith(color: color);
      _saveState();
      return;
    }
    final objIdx = objects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      objects[objIdx] = objects[objIdx].copyWith(color: color);
      _saveState();
      return;
    }
    final pIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      paths[pIdx] = paths[pIdx].copyWith(color: color);
      _saveState();
      return;
    }
    final wIdx = walls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      walls[wIdx] = walls[wIdx].copyWith(color: color);
      _saveState();
      return;
    }
  }

  void updateSelectedStrokeWidth(double width) {
    if (selectedId == null) return;
    // Hanya Wall dan Path yang punya stroke width eksplisit
    final pIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      paths[pIdx] = paths[pIdx].copyWith(strokeWidth: width);
      _saveState();
      return;
    }
    final wIdx = walls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      walls[wIdx] = walls[wIdx].copyWith(thickness: width);
      _saveState();
      return;
    }
  }

  // ... (Duplicate, Rotate, Layers, Snap Logic SAMA) ...
  void duplicateSelected() {
    if (selectedId == null) return;
    final offset = const Offset(20, 20);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final obj = objects.firstWhere((o) => o.id == selectedId);
      objects.add(obj.copyWith(id: newId, position: obj.position + offset));
    } catch (_) {}
    try {
      final shp = shapes.firstWhere((s) => s.id == selectedId);
      shapes.add(shp.copyWith(id: newId, rect: shp.rect.shift(offset)));
    } catch (_) {}
    try {
      final wall = walls.firstWhere((w) => w.id == selectedId);
      walls.add(
        wall.copyWith(
          id: newId,
          start: wall.start + offset,
          end: wall.end + offset,
        ),
      );
    } catch (_) {}
    try {
      final pth = paths.firstWhere((p) => p.id == selectedId);
      paths.add(pth.moveBy(offset).copyWith(id: newId));
    } catch (_) {}
    try {
      final lbl = labels.firstWhere((l) => l.id == selectedId);
      labels.add(lbl.moveBy(offset).copyWith(id: newId));
    } catch (_) {}
    selectedId = newId;
    _saveState();
  }

  void rotateSelected() {
    if (selectedId == null) return;
    final objIdx = objects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      objects[objIdx] = objects[objIdx].copyWith(
        rotation: objects[objIdx].rotation + (pi / 2),
      );
      _saveState();
      return;
    }
    final shpIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      shapes[shpIdx] = shapes[shpIdx].copyWith(
        rotation: shapes[shpIdx].rotation + (pi / 2),
      );
      _saveState();
      return;
    }
  }

  void bringToFront() {
    if (selectedId == null) return;
    final shpIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      shapes.add(shapes.removeAt(shpIdx));
      _saveState();
      return;
    }
    final objIdx = objects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      objects.add(objects.removeAt(objIdx));
      _saveState();
      return;
    }
  }

  void sendToBack() {
    if (selectedId == null) return;
    final shpIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      shapes.insert(0, shapes.removeAt(shpIdx));
      _saveState();
      return;
    }
    final objIdx = objects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      objects.insert(0, objects.removeAt(objIdx));
      _saveState();
      return;
    }
  }

  Offset _getSmartSnapPoint(Offset rawPos) {
    for (var wall in walls) {
      if ((rawPos - wall.start).distance < 15.0) return wall.start;
      if ((rawPos - wall.end).distance < 15.0) return wall.end;
    }
    if (enableSnap) {
      double x = (rawPos.dx / gridSize).round() * gridSize;
      double y = (rawPos.dy / gridSize).round() * gridSize;
      return Offset(x, y);
    }
    return rawPos;
  }

  // --- INPUT HANDLING (UPDATE: GUNAKAN ACTIVE COLOR/STROKE) ---
  void onPanStart(Offset localPos) {
    if (activeTool == PlanTool.select) {
      _handleSelection(localPos);
      if (selectedId != null) {
        isDragging = true;
        lastDragPos = localPos;
      }
    } else if (activeTool == PlanTool.wall || activeTool == PlanTool.shape) {
      Offset pos = (activeTool == PlanTool.wall)
          ? _getSmartSnapPoint(localPos)
          : localPos;
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
      _moveSelectedItem(localPos - lastDragPos!);
      lastDragPos = localPos;
    } else if (activeTool == PlanTool.wall && tempStart != null) {
      Offset pos = _getSmartSnapPoint(localPos);
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
    if (activeTool == PlanTool.select && isDragging) {
      isDragging = false;
      lastDragPos = null;
      _saveState();
    } else if (activeTool == PlanTool.wall &&
        tempStart != null &&
        tempEnd != null) {
      if ((tempStart! - tempEnd!).distance > 5) {
        // GUNAKAN ACTIVE COLOR & STROKE
        walls.add(
          Wall(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            start: tempStart!,
            end: tempEnd!,
            color: activeColor,
            thickness: activeStrokeWidth,
          ),
        );
        _saveState();
      }
      tempStart = null;
      tempEnd = null;
    } else if (activeTool == PlanTool.shape &&
        tempStart != null &&
        tempEnd != null) {
      // GUNAKAN ACTIVE COLOR
      shapes.add(
        PlanShape(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          rect: Rect.fromPoints(tempStart!, tempEnd!),
          type: selectedShapeType,
          color: activeColor,
        ),
      );
      _saveState();
      tempStart = null;
      tempEnd = null;
    } else if (activeTool == PlanTool.freehand &&
        currentPathPoints.isNotEmpty) {
      // GUNAKAN ACTIVE COLOR & STROKE
      paths.add(
        PlanPath(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          points: List.from(currentPathPoints),
          color: activeColor,
          strokeWidth: activeStrokeWidth,
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
      // GUNAKAN ACTIVE COLOR
      objects.add(
        PlanObject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: pos,
          name: selectedObjectName,
          description: "...",
          iconCodePoint: selectedObjectIcon!.codePoint,
          color: activeColor,
        ),
      );
      _saveState();
    } else if (activeTool == PlanTool.select) {
      if (!isDragging) _handleSelection(localPos);
    } else if (activeTool == PlanTool.eraser) {
      _handleEraser(localPos);
    }
  }

  void addLabel(Offset pos, String text) {
    // GUNAKAN ACTIVE COLOR
    labels.add(
      PlanLabel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: pos,
        text: text,
        color: activeColor,
      ),
    );
    _saveState();
    notifyListeners();
  }

  // ... (Metode _moveSelectedItem, _handleSelection, _handleEraser, Helpers geometri SAMA) ...
  void _moveSelectedItem(Offset delta) {
    final shpIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      shapes[shpIdx] = shapes[shpIdx].moveBy(delta);
      return;
    }
    final lblIdx = labels.indexWhere((l) => l.id == selectedId);
    if (lblIdx != -1) {
      labels[lblIdx] = labels[lblIdx].moveBy(delta);
      return;
    }
    final objIdx = objects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      objects[objIdx] = objects[objIdx].moveBy(delta);
      return;
    }
    final pathIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pathIdx != -1) {
      paths[pathIdx] = paths[pathIdx].moveBy(delta);
      return;
    }
    final wallIdx = walls.indexWhere((w) => w.id == selectedId);
    if (wallIdx != -1) {
      walls[wallIdx] = walls[wallIdx].moveBy(delta);
      return;
    }
  }

  void _handleSelection(Offset pos) {
    selectedId = null;
    isObjectSelected = false;
    for (var lbl in labels.reversed) {
      if ((lbl.position - pos).distance < 20.0) {
        selectedId = lbl.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    for (var obj in objects.reversed) {
      if ((obj.position - pos).distance < 25.0) {
        selectedId = obj.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    for (var shp in shapes.reversed) {
      if (shp.rect.contains(pos)) {
        selectedId = shp.id;
        isObjectSelected = true;
        notifyListeners();
        return;
      }
    }
    for (var path in paths.reversed) {
      if (_isPointNearPath(pos, path)) {
        selectedId = path.id;
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
    final lblIdx = labels.lastIndexWhere(
      (l) => (l.position - pos).distance < 20.0,
    );
    if (lblIdx != -1) {
      labels.removeAt(lblIdx);
      deleted = true;
    }
    if (!deleted) {
      final shpIdx = shapes.lastIndexWhere((s) => s.rect.contains(pos));
      if (shpIdx != -1) {
        shapes.removeAt(shpIdx);
        deleted = true;
      }
    }
    if (!deleted) {
      final objIdx = objects.lastIndexWhere(
        (o) => (o.position - pos).distance < 30.0,
      );
      if (objIdx != -1) {
        objects.removeAt(objIdx);
        deleted = true;
      }
    }
    if (!deleted) {
      final pIdx = paths.lastIndexWhere((p) => _isPointNearPath(pos, p));
      if (pIdx != -1) {
        paths.removeAt(pIdx);
        deleted = true;
      }
    }
    if (!deleted) {
      final wIdx = walls.indexWhere(
        (w) => _isPointNearLine(pos, w.start, w.end, 15.0),
      );
      if (wIdx != -1) {
        walls.removeAt(wIdx);
        deleted = true;
      }
    }
    if (deleted) _saveState();
  }

  // ... (Get Data, Update Desc, Delete, Clear, Library SAMA) ...
  Map<String, dynamic>? getSelectedItemData() {
    if (selectedId == null) return null;
    try {
      final s = shapes.firstWhere((x) => x.id == selectedId);
      return {
        'id': s.id,
        'title': s.name,
        'desc': s.description,
        'type': 'Bentuk',
        'isPath': false,
      };
    } catch (_) {}
    try {
      final l = labels.firstWhere((x) => x.id == selectedId);
      return {
        'id': l.id,
        'title': l.text,
        'desc': 'Label',
        'type': 'Label',
        'isPath': false,
      };
    } catch (_) {}
    try {
      final o = objects.firstWhere((x) => x.id == selectedId);
      return {
        'id': o.id,
        'title': o.name,
        'desc': o.description,
        'type': 'Interior',
        'isPath': false,
      };
    } catch (_) {}
    try {
      final p = paths.firstWhere((x) => x.id == selectedId);
      return {
        'id': p.id,
        'title': p.name,
        'desc': p.description,
        'type': 'Gambar',
        'isPath': true,
      };
    } catch (_) {}
    try {
      final w = walls.firstWhere((x) => x.id == selectedId);
      return {
        'id': w.id,
        'title': 'Tembok',
        'desc': w.description,
        'type': 'Struktur',
        'isPath': false,
      };
    } catch (_) {}
    return null;
  }

  void updateDescription(String newDesc, {String? newName}) {
    if (selectedId == null) return;
    final shpIdx = shapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      shapes[shpIdx] = shapes[shpIdx].copyWith(
        description: newDesc,
        name: newName,
      );
      _saveState();
      return;
    }
    final lblIdx = labels.indexWhere((l) => l.id == selectedId);
    if (lblIdx != -1 && newName != null) {
      labels[lblIdx] = labels[lblIdx].copyWith(text: newName);
      _saveState();
      return;
    }
    final objIdx = objects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      objects[objIdx] = objects[objIdx].copyWith(
        description: newDesc,
        name: newName,
      );
      _saveState();
      return;
    }
    final pIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      paths[pIdx] = paths[pIdx].copyWith(description: newDesc, name: newName);
      _saveState();
      return;
    }
    final wIdx = walls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      walls[wIdx] = walls[wIdx].copyWith(description: newDesc);
      _saveState();
      return;
    }
  }

  void deleteSelected() {
    if (selectedId == null) return;
    shapes.removeWhere((s) => s.id == selectedId);
    labels.removeWhere((l) => l.id == selectedId);
    objects.removeWhere((o) => o.id == selectedId);
    paths.removeWhere((p) => p.id == selectedId);
    walls.removeWhere((w) => w.id == selectedId);
    selectedId = null;
    _saveState();
    notifyListeners();
  }

  void clearAll() {
    shapes.clear();
    labels.clear();
    objects.clear();
    paths.clear();
    walls.clear();
    selectedId = null;
    _saveState();
    notifyListeners();
  }

  void saveCurrentSelectionToLibrary() {
    if (selectedId == null) return;
    final pathIdx = paths.indexWhere((p) => p.id == selectedId);
    if (pathIdx != -1) {
      savedCustomInteriors.add(paths[pathIdx].copyWith(isSavedAsset: true));
      notifyListeners();
    }
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
    paths.add(
      savedPath.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: newPoints,
      ),
    );
    _saveState();
    notifyListeners();
  }
}
