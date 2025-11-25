// lib/features/plan_architect/logic/mixins/plan_variables.dart
import 'package:flutter/material.dart';
import 'dart:io'; // Tambahkan import ini
import '../../data/plan_models.dart';
import '../plan_enums.dart';
import 'package:mind_palace_manager/app_settings.dart';

abstract class PlanVariables extends ChangeNotifier {
  // --- DATA UTAMA ---
  List<PlanFloor> floors = [];
  int activeFloorIndex = 0;
  List<dynamic> savedCustomInteriors = [];

  // --- TAMBAHAN: Directory Bangunan ---
  Directory? buildingDirectory;
  // ------------------------------------

  // --- GETTERS ---
  PlanFloor get activeFloor => floors[activeFloorIndex];
  List<Wall> get walls => activeFloor.walls;
  List<PlanObject> get objects => activeFloor.objects;
  List<PlanPath> get paths => activeFloor.paths;
  List<PlanLabel> get labels => activeFloor.labels;
  List<PlanShape> get shapes => activeFloor.shapes;
  List<PlanGroup> get groups => activeFloor.groups;
  List<PlanPortal> get portals => activeFloor.portals;

  // --- VIEW SETTINGS ---
  bool isViewMode = false;

  Color canvasColor = Color(AppSettings.planCanvasColor);
  bool showGrid = AppSettings.planShowGrid;
  bool showZoomButtons = AppSettings.planShowZoomButtons;

  final double canvasWidth = 500.0;
  final double canvasHeight = 500.0;

  bool layerWalls = AppSettings.planLayerWalls;
  bool layerObjects = AppSettings.planLayerObjects;
  bool layerLabels = AppSettings.planLayerLabels;
  bool layerDims = AppSettings.planLayerDims;

  bool enableSnap = true;
  double gridSize = AppSettings.planGridSize;

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

  Offset? selectionBoxStart;
  Offset? selectionBoxEnd;
  bool isBoxSelecting = false;

  IconData? selectedObjectIcon;
  String selectedObjectName = "Furniture";
  PlanShapeType selectedShapeType = PlanShapeType.rectangle;

  bool shapeFilled = true;

  // --- HISTORY STATE ---
  final List<String> historyStack = [];
  int historyIndex = -1;
  bool hasUnsavedChanges = false;
}
