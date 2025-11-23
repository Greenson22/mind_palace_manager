import 'package:flutter/material.dart';
import '../../data/plan_models.dart';
import '../plan_enums.dart';

abstract class PlanVariables extends ChangeNotifier {
  // --- DATA UTAMA ---
  List<PlanFloor> floors = [];
  int activeFloorIndex = 0;
  List<dynamic> savedCustomInteriors = [];

  // --- GETTERS ---
  PlanFloor get activeFloor => floors[activeFloorIndex];
  List<Wall> get walls => activeFloor.walls;
  List<PlanObject> get objects => activeFloor.objects;
  List<PlanPath> get paths => activeFloor.paths;
  List<PlanLabel> get labels => activeFloor.labels;
  List<PlanShape> get shapes => activeFloor.shapes;
  List<PlanGroup> get groups => activeFloor.groups;

  // --- VIEW SETTINGS ---
  bool isViewMode = false;
  Color canvasColor = Colors.white;
  bool showGrid = true;

  // --- NEW SETTING: ZOOM CONTROLS ---
  bool showZoomButtons = true; // Default: Tampilkan tombol zoom (+/-)

  final double canvasWidth = 500.0;
  final double canvasHeight = 500.0;

  bool layerWalls = true;
  bool layerObjects = true;
  bool layerLabels = true;
  bool layerDims = false;

  bool enableSnap = true;
  double gridSize = 20.0;

  final TransformationController transformController =
      TransformationController();

  // --- TOOLS ---
  PlanTool activeTool = PlanTool.select;

  Color activeColor = Colors.black;
  double activeStrokeWidth = 2.0;

  // --- INPUT STATE ---
  Offset? tempStart;
  Offset? tempEnd;
  List<Offset> currentPathPoints = [];
  bool isDragging = false;
  Offset? lastDragPos;

  // --- SELECTION STATE ---
  String? selectedId;
  bool isObjectSelected = false;
  Set<String> multiSelectedIds = {};
  bool isMultiSelectMode = false;

  IconData? selectedObjectIcon;
  String selectedObjectName = "Furniture";
  PlanShapeType selectedShapeType = PlanShapeType.rectangle;

  // --- NEW STATE: SHAPE STYLE ---
  bool shapeFilled = true; // Default: Solid

  // --- HISTORY STATE ---
  final List<String> historyStack = [];
  int historyIndex = -1;
  bool hasUnsavedChanges = false;
}
