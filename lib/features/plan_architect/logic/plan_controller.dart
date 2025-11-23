// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/plan_models.dart';

enum PlanTool {
  select,
  wall,
  object,
  text,
  eraser,
  freehand,
  shape,
  hand,
  moveAll,
}

class PlanController extends ChangeNotifier {
  List<PlanFloor> floors = [];
  int activeFloorIndex = 0;
  List<PlanPath> savedCustomInteriors = [];

  PlanFloor get activeFloor => floors[activeFloorIndex];
  List<Wall> get walls => activeFloor.walls;
  List<PlanObject> get objects => activeFloor.objects;
  List<PlanPath> get paths => activeFloor.paths;
  List<PlanLabel> get labels => activeFloor.labels;
  List<PlanShape> get shapes => activeFloor.shapes;

  bool isViewMode = false;
  Color canvasColor = Colors.white;
  bool showGrid = true;

  // CANVAS SIZE FIXED 500x500
  final double canvasWidth = 500.0;
  final double canvasHeight = 500.0;

  bool layerWalls = true;
  bool layerObjects = true;
  bool layerLabels = true;

  // --- PERUBAHAN 1: Default layerDims jadi false ---
  bool layerDims = false;

  bool enableSnap = true;

  // --- PERUBAHAN 2: Grid Size tidak final agar bisa diubah ---
  double gridSize = 20.0;

  PlanTool activeTool = PlanTool.select;

  Color activeColor = Colors.black;
  double activeStrokeWidth = 2.0;

  Offset? tempStart;
  Offset? tempEnd;
  List<Offset> currentPathPoints = [];
  bool isDragging = false;
  Offset? lastDragPos;
  String? selectedId;
  bool isObjectSelected = false;

  IconData? selectedObjectIcon;
  String selectedObjectName = "Furniture";
  PlanShapeType selectedShapeType = PlanShapeType.rectangle;

  final TransformationController transformController =
      TransformationController();
  final List<String> _history = [];
  int _historyIndex = -1;

  // --- PERUBAHAN 3: Flag Unsaved Changes ---
  bool hasUnsavedChanges = false;

  PlanController() {
    if (floors.isEmpty) {
      floors.add(PlanFloor(id: 'floor_1', name: 'Lantai 1'));
    }
    // Reset flag saat init karena baru load
    hasUnsavedChanges = false;
    _saveState(initial: true);
  }

  // ... (Fungsi addFloor, removeActiveFloor, setActiveFloor, renameActiveFloor SAMA) ...
  void addFloor() {
    final newId = 'floor_${floors.length + 1}';
    floors.add(PlanFloor(id: newId, name: 'Lantai ${floors.length + 1}'));
    activeFloorIndex = floors.length - 1;
    selectedId = null;
    _saveState();
  }

  void removeActiveFloor() {
    if (floors.length <= 1) return;
    floors.removeAt(activeFloorIndex);
    if (activeFloorIndex >= floors.length) activeFloorIndex = floors.length - 1;
    selectedId = null;
    _saveState();
  }

  void setActiveFloor(int index) {
    if (index >= 0 && index < floors.length) {
      activeFloorIndex = index;
      selectedId = null;
      notifyListeners();
    }
  }

  void renameActiveFloor(String newName) {
    floors[activeFloorIndex] = floors[activeFloorIndex].copyWith(name: newName);
    _saveState();
  }

  void _updateActiveFloor({
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

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  // --- PERUBAHAN 3: Update flag unsaved changes ---
  void _saveState({bool initial = false}) {
    if (_historyIndex < _history.length - 1)
      _history.removeRange(_historyIndex + 1, _history.length);
    final state = jsonEncode({
      'floors': floors.map((f) => f.toJson()).toList(),
      'activeIdx': activeFloorIndex,
      'cc': canvasColor.value,
    });
    _history.add(state);
    _historyIndex++;
    if (_history.length > 30) {
      _history.removeAt(0);
      _historyIndex--;
    }

    if (!initial) {
      hasUnsavedChanges = true;
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
    floors = (data['floors'] as List)
        .map((e) => PlanFloor.fromJson(e))
        .toList();
    activeFloorIndex = data['activeIdx'] ?? 0;
    if (data['cc'] != null) canvasColor = Color(data['cc']);
    if (activeFloorIndex >= floors.length) activeFloorIndex = 0;
    selectedId = null;
    // Saat undo/redo, kita anggap ada perubahan status state
    notifyListeners();
  }

  // ... (Bagian View/Layer Settings) ...
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
    _saveState();
  }

  void toggleGridVisibility() {
    showGrid = !showGrid;
    notifyListeners();
  }

  // --- PERUBAHAN 2: Fungsi Ubah Grid Size ---
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

  // ... (SetTool, Zoom, dll SAMA) ...
  void setTool(PlanTool tool) {
    activeTool = tool;
    selectedId = null;
    isDragging = false;
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

  void clearAll() {
    _updateActiveFloor(
      walls: [],
      objects: [],
      paths: [],
      labels: [],
      shapes: [],
    );
    selectedId = null;
    _saveState();
  }

  // ... (Snap Logic SAMA) ...
  Offset _snapToGrid(Offset pos) {
    double x = (pos.dx / gridSize).round() * gridSize;
    double y = (pos.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }

  Offset _getSmartSnapPoint(Offset rawPos) {
    for (var wall in walls) {
      if ((rawPos - wall.start).distance < 15.0) return wall.start;
      if ((rawPos - wall.end).distance < 15.0) return wall.end;
    }
    if (enableSnap) return _snapToGrid(rawPos);
    return rawPos;
  }

  // ... (Pan Start/Update/End SAMA - dengan Move All yang sudah ada) ...
  void onPanStart(Offset localPos) {
    if (isViewMode) return;
    if (activeTool == PlanTool.hand) return;

    if (activeTool == PlanTool.select) {
      _handleSelection(localPos);
      if (selectedId != null) {
        isDragging = true;
        lastDragPos = enableSnap ? _snapToGrid(localPos) : localPos;
      }
    } else if (activeTool == PlanTool.moveAll) {
      isDragging = true;
      lastDragPos = localPos;
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
    if (isViewMode || activeTool == PlanTool.hand) return;

    if (activeTool == PlanTool.select &&
        isDragging &&
        selectedId != null &&
        lastDragPos != null) {
      Offset targetPos = enableSnap ? _snapToGrid(localPos) : localPos;
      final delta = targetPos - lastDragPos!;
      if (delta.distanceSquared > 0) {
        _moveSelectedItem(delta);
        lastDragPos = targetPos;
      }
    } else if (activeTool == PlanTool.moveAll &&
        isDragging &&
        lastDragPos != null) {
      final delta = localPos - lastDragPos!;
      _moveAllContent(delta);
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
    if (isViewMode || activeTool == PlanTool.hand) return;

    if (activeTool == PlanTool.select && isDragging) {
      isDragging = false;
      lastDragPos = null;
      _saveState();
    } else if (activeTool == PlanTool.moveAll && isDragging) {
      isDragging = false;
      lastDragPos = null;
      _saveState();
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
        _updateActiveFloor(walls: [...walls, newWall]);
        _saveState();
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
      );
      _updateActiveFloor(shapes: [...shapes, newShape]);
      _saveState();
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
      _updateActiveFloor(paths: [...paths, newPath]);
      currentPathPoints = [];
      _saveState();
    }
    notifyListeners();
  }

  // ... (TapUp, AddLabel, MoveAllContent, MoveSelectedItem SAMA) ...
  void onTapUp(Offset localPos) {
    if (isViewMode) {
      _handleSelection(localPos);
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

    if (activeTool == PlanTool.hand || activeTool == PlanTool.moveAll) return;

    if (activeTool == PlanTool.object && selectedObjectIcon != null) {
      Offset pos = enableSnap ? _snapToGrid(localPos) : localPos;
      final newObj = PlanObject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: pos,
        name: selectedObjectName,
        description: "...",
        iconCodePoint: selectedObjectIcon!.codePoint,
        color: activeColor,
        size: 14.0,
      );
      _updateActiveFloor(objects: [...objects, newObj]);
      _saveState();
    } else if (activeTool == PlanTool.select) {
      if (!isDragging) _handleSelection(localPos);
    } else if (activeTool == PlanTool.eraser) {
      _handleEraser(localPos);
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
    _updateActiveFloor(labels: [...labels, newLbl]);
    _saveState();
  }

  void _moveAllContent(Offset delta) {
    final newWalls = walls.map((w) => w.moveBy(delta)).toList();
    final newObjects = objects.map((o) => o.moveBy(delta)).toList();
    final newPaths = paths.map((p) => p.moveBy(delta)).toList();
    final newLabels = labels.map((l) => l.moveBy(delta)).toList();
    final newShapes = shapes.map((s) => s.moveBy(delta)).toList();

    _updateActiveFloor(
      walls: newWalls,
      objects: newObjects,
      paths: newPaths,
      labels: newLabels,
      shapes: newShapes,
    );
  }

  void _moveSelectedItem(Offset delta) {
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes[shpIdx] = newShapes[shpIdx].moveBy(delta);
      _updateActiveFloor(shapes: newShapes);
      return;
    }
    List<PlanLabel> newLabels = List.from(labels);
    final lblIdx = newLabels.indexWhere((l) => l.id == selectedId);
    if (lblIdx != -1) {
      newLabels[lblIdx] = newLabels[lblIdx].moveBy(delta);
      _updateActiveFloor(labels: newLabels);
      return;
    }
    List<PlanObject> newObjects = List.from(objects);
    final objIdx = newObjects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjects[objIdx] = newObjects[objIdx].moveBy(delta);
      _updateActiveFloor(objects: newObjects);
      return;
    }
    List<PlanPath> newPaths = List.from(paths);
    final pIdx = newPaths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      newPaths[pIdx] = newPaths[pIdx].moveBy(delta);
      _updateActiveFloor(paths: newPaths);
      return;
    }
    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      newWalls[wIdx] = newWalls[wIdx].moveBy(delta);
      _updateActiveFloor(walls: newWalls);
      return;
    }
  }

  // ... (deleteSelected, updateSelectedAttribute, _handleSelection SAMA) ...
  void deleteSelected() {
    if (selectedId == null) return;
    _updateActiveFloor(
      shapes: List.from(shapes)..removeWhere((s) => s.id == selectedId),
      labels: List.from(labels)..removeWhere((l) => l.id == selectedId),
      objects: List.from(objects)..removeWhere((o) => o.id == selectedId),
      paths: List.from(paths)..removeWhere((p) => p.id == selectedId),
      walls: List.from(walls)..removeWhere((w) => w.id == selectedId),
    );
    selectedId = null;
    _saveState();
  }

  void updateSelectedAttribute({
    Color? color,
    double? stroke,
    String? desc,
    String? name,
    String? navTarget,
  }) {
    if (selectedId == null) return;

    List<PlanObject> newObjects = List.from(objects);
    final objIdx = newObjects.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjects[objIdx] = newObjects[objIdx].copyWith(
        color: color,
        description: desc,
        name: name,
        navTargetFloorId: navTarget,
        size: stroke,
      );
      _updateActiveFloor(objects: newObjects);
      _saveState();
      return;
    }

    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      newWalls[wIdx] = newWalls[wIdx].copyWith(
        color: color,
        thickness: stroke,
        description: desc,
      );
      _updateActiveFloor(walls: newWalls);
      _saveState();
      return;
    }

    List<PlanPath> newPaths = List.from(paths);
    final pIdx = newPaths.indexWhere((p) => p.id == selectedId);
    if (pIdx != -1) {
      newPaths[pIdx] = newPaths[pIdx].copyWith(
        color: color,
        strokeWidth: stroke,
        description: desc,
        name: name,
      );
      _updateActiveFloor(paths: newPaths);
      _saveState();
      return;
    }

    List<PlanLabel> newLabels = List.from(labels);
    final lIdx = newLabels.indexWhere((l) => l.id == selectedId);
    if (lIdx != -1) {
      newLabels[lIdx] = newLabels[lIdx].copyWith(
        color: color,
        text: name,
        fontSize: stroke,
      );
      _updateActiveFloor(labels: newLabels);
      _saveState();
      return;
    }

    List<PlanShape> newShapes = List.from(shapes);
    final sIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (sIdx != -1) {
      PlanShape oldShape = newShapes[sIdx];
      Rect newRect = oldShape.rect;
      if (stroke != null) {
        final center = oldShape.rect.center;
        final aspectRatio = oldShape.rect.height / oldShape.rect.width;
        final newWidth = stroke * 10;
        final newHeight = newWidth * aspectRatio;
        newRect = Rect.fromCenter(
          center: center,
          width: newWidth,
          height: newHeight,
        );
      }

      newShapes[sIdx] = oldShape.copyWith(
        color: color,
        description: desc,
        name: name,
        rect: stroke != null ? newRect : null,
      );
      _updateActiveFloor(shapes: newShapes);
      _saveState();
      return;
    }
  }

  // --- PERUBAHAN 4: Fungsi Update Panjang Tembok/Garis ---
  void updateSelectedWallLength(double newLengthInMeters) {
    if (selectedId == null) return;

    // 1. Cek Wall
    List<Wall> newWalls = List.from(walls);
    final wIdx = newWalls.indexWhere((w) => w.id == selectedId);
    if (wIdx != -1) {
      final oldWall = newWalls[wIdx];
      // Konversi meter ke pixel (1 meter = 40 px, asumsi skala)
      final double newLengthPx = newLengthInMeters * 40.0;

      // Hitung vektor arah
      final double dx = oldWall.end.dx - oldWall.start.dx;
      final double dy = oldWall.end.dy - oldWall.start.dy;
      final double currentLen = sqrt(dx * dx + dy * dy);

      if (currentLen == 0) return;

      // Normalisasi dan perpanjang dari titik Start
      final double unitX = dx / currentLen;
      final double unitY = dy / currentLen;

      final Offset newEnd = Offset(
        oldWall.start.dx + (unitX * newLengthPx),
        oldWall.start.dy + (unitY * newLengthPx),
      );

      newWalls[wIdx] = oldWall.copyWith(end: newEnd);
      _updateActiveFloor(walls: newWalls);
      _saveState();
      return;
    }
  }
  // -------------------------------------------------------

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
    _handleSelection(pos);
    if (selectedId != null) deleteSelected();
  }

  void updateSelectedColor(Color color) {
    updateSelectedAttribute(color: color);
  }

  void updateSelectedStrokeWidth(double width) {
    updateSelectedAttribute(stroke: width);
  }

  void duplicateSelected() {
    if (selectedId == null) return;
    final offset = const Offset(20, 20);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final obj = objects.firstWhere((o) => o.id == selectedId);
      _updateActiveFloor(
        objects: [
          ...objects,
          obj.copyWith(id: newId, position: obj.position + offset),
        ],
      );
    } catch (_) {}
    try {
      final shp = shapes.firstWhere((s) => s.id == selectedId);
      _updateActiveFloor(
        shapes: [
          ...shapes,
          shp.copyWith(id: newId, rect: shp.rect.shift(offset)),
        ],
      );
    } catch (_) {}
    try {
      final wall = walls.firstWhere((w) => w.id == selectedId);
      _updateActiveFloor(
        walls: [
          ...walls,
          wall.copyWith(
            id: newId,
            start: wall.start + offset,
            end: wall.end + offset,
          ),
        ],
      );
    } catch (_) {}
    try {
      final pth = paths.firstWhere((p) => p.id == selectedId);
      _updateActiveFloor(
        paths: [
          ...paths,
          pth.moveBy(offset).copyWith(id: newId),
        ],
      );
    } catch (_) {}
    try {
      final lbl = labels.firstWhere((l) => l.id == selectedId);
      _updateActiveFloor(
        labels: [
          ...labels,
          lbl.moveBy(offset).copyWith(id: newId),
        ],
      );
    } catch (_) {}
    selectedId = newId;
    _saveState();
  }

  void rotateSelected() {
    if (selectedId == null) return;
    List<PlanObject> newObjs = List.from(objects);
    final objIdx = newObjs.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjs[objIdx] = newObjs[objIdx].copyWith(
        rotation: newObjs[objIdx].rotation + (pi / 2),
      );
      _updateActiveFloor(objects: newObjs);
      _saveState();
      return;
    }
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes[shpIdx] = newShapes[shpIdx].copyWith(
        rotation: newShapes[shpIdx].rotation + (pi / 2),
      );
      _updateActiveFloor(shapes: newShapes);
      _saveState();
      return;
    }
  }

  void bringToFront() {
    if (selectedId == null) return;
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes.add(newShapes.removeAt(shpIdx));
      _updateActiveFloor(shapes: newShapes);
      _saveState();
      return;
    }
    List<PlanObject> newObjs = List.from(objects);
    final objIdx = newObjs.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjs.add(newObjs.removeAt(objIdx));
      _updateActiveFloor(objects: newObjs);
      _saveState();
      return;
    }
  }

  void sendToBack() {
    if (selectedId == null) return;
    List<PlanShape> newShapes = List.from(shapes);
    final shpIdx = newShapes.indexWhere((s) => s.id == selectedId);
    if (shpIdx != -1) {
      newShapes.insert(0, newShapes.removeAt(shpIdx));
      _updateActiveFloor(shapes: newShapes);
      _saveState();
      return;
    }
    List<PlanObject> newObjs = List.from(objects);
    final objIdx = newObjs.indexWhere((o) => o.id == selectedId);
    if (objIdx != -1) {
      newObjs.insert(0, newObjs.removeAt(objIdx));
      _updateActiveFloor(objects: newObjs);
      _saveState();
      return;
    }
  }

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
        'nav': null,
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
        'nav': null,
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
        'nav': o.navTargetFloorId,
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
        'nav': null,
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
        'nav': null,
      };
    } catch (_) {}
    return null;
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
    final newPath = savedPath.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: newPoints,
    );
    _updateActiveFloor(paths: [...paths, newPath]);
    _saveState();
    notifyListeners();
  }
}
