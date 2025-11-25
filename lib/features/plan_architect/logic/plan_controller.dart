// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert'; // Diperlukan untuk jsonDecode
import 'package:flutter/material.dart'; // Diperlukan untuk Color, Offset, debugPrint

// --- IMPORT INI YANG SEBELUMNYA HILANG (PENYEBAB ERROR) ---
import '../data/plan_models.dart'; // Diperlukan untuk PlanShape, PlanPath, PlanGroup
// ---------------------------------------------------------

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
  }

  // --- FITUR GENERATIVE UI (AI IMPORT) ---
  void importInteriorFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final String name = data['name'] ?? 'Objek AI';
      final List<dynamic> elements = data['elements'] ?? [];

      List<PlanShape> shapes = [];
      List<PlanPath> paths = [];

      // ID unik untuk grup baru
      final String groupId = DateTime.now().millisecondsSinceEpoch.toString();
      // Tempatkan di tengah kanvas (variabel dari PlanVariables)
      final Offset centerPos = Offset(canvasWidth / 2, canvasHeight / 2);

      for (var el in elements) {
        String type = el['type'];

        // Offset relatif elemen terhadap pusat grup
        double x = (el['x'] as num).toDouble();
        double y = (el['y'] as num).toDouble();

        // Parsing Warna (Support format #RRGGBB)
        String colorStr = el['color'].toString();
        if (colorStr.startsWith('#')) {
          colorStr = colorStr.replaceAll('#', '0xFF');
        }
        // Fallback jika format warnanya hanya angka hex string tanpa prefix
        if (!colorStr.startsWith('0x')) {
          // Asumsi jika 6 karakter hex, tambahkan opasitas penuh
          if (colorStr.length == 6) colorStr = '0xFF$colorStr';
        }

        Color color;
        try {
          color = Color(int.parse(colorStr));
        } catch (_) {
          color = Colors.black; // Default fallback
        }

        if (type == 'shape') {
          double w = (el['w'] as num).toDouble();
          double h = (el['h'] as num).toDouble();

          // Mapping string ke Enum PlanShapeType
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
              points: points, // Point ini relatif terhadap (0,0) lokal grup
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
          isSavedAsset: true, // Simpan agar bisa dipakai lagi dari menu Custom
        );

        // Masukkan ke dalam daftar objek aktif (PlanGroupMixin / PlanStateMixin)
        updateActiveFloor(groups: [...groups, newGroup]);

        // Simpan ke library custom juga (PlanVariables)
        savedCustomInteriors.add(newGroup);

        saveState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal import JSON AI: $e");
      // Note: Idealnya tambahkan callback onError untuk menampilkan SnackBar di UI
    }
  }
}
