// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert';
import 'dart:math' as math; // Ditambahkan untuk random ID
import 'dart:ui'; // Import UI untuk Color
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

  // --- FITUR GENERATIVE UI (AI IMPORT OBJEK) ---
  void importInteriorFromJson(String jsonString) {
    try {
      // 1. Validasi Parsing JSON Dasar
      dynamic decoded;
      try {
        decoded = jsonDecode(jsonString);
      } catch (e) {
        throw FormatException(
          "Format JSON tidak valid. Pastikan tidak ada teks lain selain kode JSON.\nDetail: $e",
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          "JSON harus berupa Object {}, bukan Array [] atau string biasa.",
        );
      }

      final Map<String, dynamic> data = decoded;
      final String name = data['name'] ?? 'Objek AI';

      // 2. Validasi Key 'elements'
      if (!data.containsKey('elements')) {
        throw const FormatException(
          "JSON tidak memiliki key 'elements'. Pastikan struktur JSON sesuai template.",
        );
      }

      final List<dynamic> elements = data['elements'] ?? [];
      if (elements.isEmpty) {
        throw const FormatException(
          "List 'elements' kosong. Tidak ada objek untuk digambar.",
        );
      }

      List<PlanShape> shapes = [];
      List<PlanPath> paths = [];

      final String groupId = DateTime.now().millisecondsSinceEpoch.toString();
      // Posisi tengah canvas
      final Offset centerPos = Offset(canvasWidth / 2, canvasHeight / 2);

      // 3. Loop Elements dengan Error Catching per item
      for (int i = 0; i < elements.length; i++) {
        try {
          var el = elements[i];
          if (el is! Map) continue; // Skip jika bukan object

          String type = el['type'] ?? 'unknown';

          double x = (el['x'] as num?)?.toDouble() ?? 0.0;
          double y = (el['y'] as num?)?.toDouble() ?? 0.0;

          // Parsing Warna yang Fleksibel
          String colorStr = el['color'].toString();
          if (colorStr.startsWith('#')) {
            colorStr = colorStr.replaceAll('#', '0xFF');
          } else if (!colorStr.startsWith('0x') && colorStr.length == 6) {
            // Asumsi hex tanpa prefix (e.g., FFFFFF)
            colorStr = '0xFF$colorStr';
          }

          Color color;
          try {
            color = Color(int.parse(colorStr));
          } catch (_) {
            color = Colors.black;
          }

          if (type == 'shape') {
            double w = (el['w'] as num?)?.toDouble() ?? 20.0;
            double h = (el['h'] as num?)?.toDouble() ?? 20.0;

            String shapeTypeStr = el['shapeType'] ?? 'rectangle';

            // Mencari Enum yang cocok
            PlanShapeType shapeType = PlanShapeType.values.firstWhere(
              (e) => e.toString().split('.').last == shapeTypeStr,
              orElse: () => PlanShapeType.rectangle,
            );

            shapes.add(
              PlanShape(
                id: "${groupId}_s_${shapes.length}",
                rect: Rect.fromCenter(
                  center: Offset(x, y),
                  width: w,
                  height: h,
                ),
                type: shapeType,
                color: color,
                isFilled: el['filled'] ?? true,
                name: "Bagian $name",
              ),
            );
          } else if (type == 'path') {
            List<dynamic> pointsData = el['points'] ?? [];
            if (pointsData.isEmpty) continue;

            List<Offset> points = pointsData.map((p) {
              if (p is List && p.length >= 2) {
                return Offset(
                  (p[0] as num).toDouble(),
                  (p[1] as num).toDouble(),
                );
              }
              return Offset.zero;
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
        } catch (e) {
          debugPrint("Error parsing element index $i: $e");
          // Lanjutkan ke elemen berikutnya (skip yang error)
        }
      }

      // 4. Cek apakah ada hasil
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
      } else {
        throw Exception(
          "Gagal memproses elemen. Tidak ada shape atau path yang valid ditemukan dalam JSON.",
        );
      }
    } catch (e) {
      // Rethrow agar UI bisa menangkap pesan error asli
      rethrow;
    }
  }

  // --- FITUR BARU: IMPORT DENAH LENGKAP DARI AI ---
  void importFullPlanFromJson(String jsonString) {
    try {
      // 1. Parsing JSON
      dynamic decoded;
      try {
        decoded = jsonDecode(jsonString);
      } catch (e) {
        throw FormatException(
          "Format JSON tidak valid. Pastikan hanya menyalin kode JSON.\nError: $e",
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          "JSON harus berupa Object {}, bukan Array.",
        );
      }

      final Map<String, dynamic> data = decoded;

      // Bersihkan denah saat ini (Opsional, uncomment jika ingin reset total)
      // clearAll();

      List<Wall> newWalls = [];
      List<PlanObject> newObjects = [];
      List<PlanLabel> newLabels = [];

      // 2. Parse Walls (Tembok)
      if (data.containsKey('walls') && data['walls'] is List) {
        final List wallsData = data['walls'];
        for (var w in wallsData) {
          newWalls.add(
            Wall(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  math.Random().nextInt(1000).toString(),
              start: Offset(
                (w['sx'] as num).toDouble(),
                (w['sy'] as num).toDouble(),
              ),
              end: Offset(
                (w['ex'] as num).toDouble(),
                (w['ey'] as num).toDouble(),
              ),
              thickness: 4.0, // Default tebal tembok
              color: Colors.black,
            ),
          );
        }
      }

      // 3. Parse Loci (Objek Memori)
      if (data.containsKey('loci') && data['loci'] is List) {
        final List lociData = data['loci'];
        for (var l in lociData) {
          // Mapping icon string ke IconData (Sederhana)
          IconData icon = Icons.circle;
          String iconName = (l['icon'] ?? '').toString().toLowerCase();
          if (iconName.contains('door'))
            icon = Icons.door_front_door;
          else if (iconName.contains('window'))
            icon = Icons.window;
          else if (iconName.contains('bed'))
            icon = Icons.bed;
          else if (iconName.contains('chair'))
            icon = Icons.chair;
          else if (iconName.contains('tv'))
            icon = Icons.tv;
          else if (iconName.contains('table'))
            icon = Icons.table_bar;
          else if (iconName.contains('shelf'))
            icon = Icons.shelves;
          else if (iconName.contains('plant'))
            icon = Icons.local_florist;

          // Gunakan nomor urut jika ada
          String name = l['name'] ?? "Loci";

          newObjects.add(
            PlanObject(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  math.Random().nextInt(1000).toString(),
              position: Offset(
                (l['x'] as num).toDouble(),
                (l['y'] as num).toDouble(),
              ),
              name: name,
              description: l['desc'] ?? "Titik memori",
              iconCodePoint: icon.codePoint,
              size: 20.0,
              color: Colors.blueAccent,
            ),
          );

          // Tambah label angka/nama di dekat objek
          newLabels.add(
            PlanLabel(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  math.Random().nextInt(1000).toString(),
              position: Offset(
                (l['x'] as num).toDouble(),
                (l['y'] as num).toDouble() + 25,
              ),
              text: name,
              fontSize: 10.0,
              color: Colors.black87,
            ),
          );
        }
      }

      if (newWalls.isEmpty && newObjects.isEmpty) {
        throw Exception(
          "JSON tidak berisi data 'walls' atau 'loci' yang valid.",
        );
      }

      // 4. Update State
      updateActiveFloor(
        walls: [...walls, ...newWalls],
        objects: [...objects, ...newObjects],
        labels: [...labels, ...newLabels],
      );
      saveState();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
