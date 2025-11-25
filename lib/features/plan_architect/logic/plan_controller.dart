// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart';
import '../data/plan_models.dart';

import 'mixins/plan_variables.dart';
import 'mixins/plan_state_mixin.dart';
import 'mixins/plan_view_mixin.dart';
import 'mixins/plan_tool_mixin.dart';
import 'mixins/plan_image_mixin.dart';
import 'mixins/plan_input_mixin.dart';
import 'mixins/plan_selection_core_mixin.dart';
import 'mixins/plan_transform_mixin.dart';
import 'mixins/plan_group_mixin.dart';
import 'mixins/plan_edit_mixin.dart';
import 'plan_enums.dart';

export 'plan_enums.dart';

class PlanController extends PlanVariables
    with
        PlanStateMixin,
        PlanViewMixin,
        PlanToolMixin,
        PlanImageMixin,
        PlanSelectionCoreMixin,
        PlanTransformMixin,
        PlanGroupMixin,
        PlanEditMixin,
        PlanInputMixin {
  PlanController() {
    activeTool = PlanTool.select;
    initFloors();
    _loadGlobalLibrary();
  }

  void _loadGlobalLibrary() {
    savedCustomInteriors.clear();
    for (String jsonStr in AppSettings.customLibraryJson) {
      try {
        final map = jsonDecode(jsonStr);
        if (map['metaType'] == 'PlanGroup') {
          savedCustomInteriors.add(PlanGroup.fromJson(map['data']));
        } else if (map['metaType'] == 'PlanPath') {
          savedCustomInteriors.add(PlanPath.fromJson(map['data']));
        }
      } catch (e) {
        debugPrint("Gagal load asset custom: $e");
      }
    }
  }

  // --- FITUR GENERATIVE UI (AI IMPORT) ---
  void importInteriorFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final String name = data['name'] ?? 'Objek AI';
      final List<dynamic> elements = data['elements'] ?? [];

      List<PlanShape> shapes = [];
      List<PlanPath> paths = [];

      final String groupId = DateTime.now().millisecondsSinceEpoch.toString();
      final Offset centerPos = Offset(canvasWidth / 2, canvasHeight / 2);

      for (var el in elements) {
        String type = el['type'];

        double x = (el['x'] as num).toDouble();
        double y = (el['y'] as num).toDouble();

        // Parsing Warna
        String colorStr = el['color'].toString();
        if (colorStr.startsWith('#')) {
          colorStr = colorStr.replaceAll('#', '0xFF');
        }
        if (!colorStr.startsWith('0x')) {
          if (colorStr.length == 6) colorStr = '0xFF$colorStr';
        }

        Color color;
        try {
          color = Color(int.parse(colorStr));
        } catch (_) {
          color = Colors.black;
        }

        if (type == 'shape') {
          double w = (el['w'] as num).toDouble();
          double h = (el['h'] as num).toDouble();

          String shapeTypeStr = el['shapeType'] ?? 'rectangle';
          PlanShapeType shapeType = PlanShapeType.values.firstWhere(
            (e) => e.toString().split('.').last == shapeTypeStr,
            orElse: () => PlanShapeType.rectangle,
          );

          shapes.add(
            PlanShape(
              id: "${groupId}_s_${shapes.length}",
              rect: Rect.fromCenter(center: Offset(x, y), width: w, height: h),
              type: shapeType,
              color: color,
              isFilled: el['filled'] ?? true,
              name: "Bagian $name",
            ),
          );
        } else if (type == 'path') {
          List<dynamic> pointsData = el['points'];
          List<Offset> points = pointsData.map((p) {
            return Offset((p[0] as num).toDouble(), (p[1] as num).toDouble());
          }).toList();

          paths.add(
            PlanPath(
              id: "${groupId}_p_${paths.length}",
              points: points,
              color: color,
              strokeWidth: (el['width'] as num?)?.toDouble() ?? 2.0,
            ),
          );
        }
      }

      if (shapes.isNotEmpty || paths.isNotEmpty) {
        final newGroup = PlanGroup(
          id: groupId,
          position: centerPos,
          name: name,
          description: "Dibuat oleh Gemini AI",
          shapes: shapes,
          paths: paths,
          isSavedAsset: true,
        );

        updateActiveFloor(groups: [...groups, newGroup]);

        // Simpan otomatis ke library global
        savedCustomInteriors.add(newGroup);
        final jsonStr = jsonEncode({
          'metaType': 'PlanGroup',
          'data': newGroup.toJson(),
        });
        AppSettings.addCustomAsset(jsonStr);

        saveState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal import JSON AI: $e");
    }
  }
}
