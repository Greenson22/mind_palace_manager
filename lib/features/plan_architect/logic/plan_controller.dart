// lib/features/plan_architect/logic/plan_controller.dart
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
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

  // --- FITUR GENERATIVE UI (AI IMPORT OBJEK TUNGGAL) ---
  void importInteriorFromJson(String jsonString) {
    try {
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
      final Offset centerPos = Offset(canvasWidth / 2, canvasHeight / 2);

      for (int i = 0; i < elements.length; i++) {
        try {
          var el = elements[i];
          if (el is! Map) continue;

          String type = el['type'] ?? 'unknown';

          double x = (el['x'] as num?)?.toDouble() ?? 0.0;
          double y = (el['y'] as num?)?.toDouble() ?? 0.0;

          String colorStr = el['color'].toString();
          if (colorStr.startsWith('#')) {
            colorStr = colorStr.replaceAll('#', '0xFF');
          } else if (!colorStr.startsWith('0x') && colorStr.length == 6) {
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
      rethrow;
    }
  }

  // --- FITUR BARU: IMPORT DENAH LENGKAP (TEMBOK + PORTAL + LOCI) ---
  void importFullPlanFromJson(String jsonString, {bool addLabels = true}) {
    try {
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

      List<Wall> newWalls = [];
      List<PlanPortal> newPortals = [];
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
              thickness: 4.0,
              color: Colors.black,
              // --- BACA DESKRIPSI ---
              description: w['desc'] ?? 'Tembok',
            ),
          );
        }
      }

      // 3. Parse Portals (Pintu & Jendela)
      if (data.containsKey('portals') && data['portals'] is List) {
        final List portalsData = data['portals'];
        for (var p in portalsData) {
          String typeStr = (p['type'] ?? 'door').toString().toLowerCase();
          PlanPortalType portalType = typeStr.contains('window')
              ? PlanPortalType.window
              : PlanPortalType.door;

          double rotDeg = (p['rot'] as num?)?.toDouble() ?? 0.0;
          double rotRad = rotDeg * (math.pi / 180.0);

          newPortals.add(
            PlanPortal(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  math.Random().nextInt(1000).toString(),
              position: Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ),
              rotation: rotRad,
              width: 40.0,
              type: portalType,
              color: Colors.brown,
              // --- BACA DESKRIPSI ---
              description: p['desc'] ?? '',
            ),
          );
        }
      }

      // 4. Parse Loci (Objek Interior)
      if (data.containsKey('loci') && data['loci'] is List) {
        final List lociData = data['loci'];
        for (var l in lociData) {
          IconData icon = Icons.circle;
          String iconName = (l['icon'] ?? '').toString().toLowerCase();

          if (iconName.contains('door') || iconName.contains('window')) {
            continue;
          }

          if (iconName.contains('bed'))
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
          else if (iconName.contains('sofa'))
            icon = Icons.weekend;
          else if (iconName.contains('bath') || iconName.contains('toilet'))
            icon = Icons.bathtub;

          String name = l['name'] ?? "Loci";
          double size = (l['size'] as num?)?.toDouble() ?? 20.0;

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
              // --- DESKRIPSI LOCI SUDAH ADA ---
              description: l['desc'] ?? "Titik memori",
              iconCodePoint: icon.codePoint,
              size: size,
              color: Colors.blueAccent,
            ),
          );

          // Tambah label jika opsi aktif
          if (addLabels) {
            newLabels.add(
              PlanLabel(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    math.Random().nextInt(1000).toString(),
                position: Offset(
                  (l['x'] as num).toDouble(),
                  (l['y'] as num).toDouble() + (size / 2) + 10,
                ),
                text: name,
                fontSize: 10.0,
                color: Colors.black87,
              ),
            );
          }
        }
      }

      if (newWalls.isEmpty && newObjects.isEmpty && newPortals.isEmpty) {
        throw Exception(
          "JSON tidak berisi data valid (walls, portals, atau loci).",
        );
      }

      updateActiveFloor(
        walls: [...walls, ...newWalls],
        objects: [...objects, ...newObjects],
        portals: [...portals, ...newPortals],
        labels: [...labels, ...newLabels],
      );
      saveState();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
