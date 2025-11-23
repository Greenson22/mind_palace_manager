import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart'; // Tambahan untuk akses Icons & Colors
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class DistrictBuildingLogic {
  final Directory districtDirectory;

  DistrictBuildingLogic(this.districtDirectory);

  // --- Load Data ---
  Future<List<Directory>> loadBuildings() async {
    if (!await districtDirectory.exists()) {
      await districtDirectory.create(recursive: true);
    }
    final entities = await districtDirectory.list().toList();
    return entities.whereType<Directory>().toList();
  }

  // --- Create ---
  Future<void> createBuilding(
    String name,
    String type,
    String? iconType,
    dynamic iconData, {
    String? sourceImagePath,
  }) async {
    final newBuildingPath = p.join(districtDirectory.path, name);
    final newDir = Directory(newBuildingPath);
    await newDir.create(recursive: true);

    String? finalIconData = iconData;

    // Jika ikon gambar, copy file
    if (iconType == 'image' && sourceImagePath != null) {
      final extension = p.extension(sourceImagePath);
      final uniqueIconName =
          'icon_${DateTime.now().millisecondsSinceEpoch}$extension';
      finalIconData = uniqueIconName;
      final sourceFile = File(sourceImagePath);
      await sourceFile.copy(p.join(newBuildingPath, uniqueIconName));
    }

    final dataJsonFile = File(p.join(newBuildingPath, 'data.json'));
    final jsonData = {
      "icon_type": iconType,
      "icon_data": finalIconData,
      "type": type,
      "rooms": [],
      "plans": [], // Inisialisasi array plans kosong
    };
    await dataJsonFile.writeAsString(json.encode(jsonData));
  }

  // --- Update ---
  Future<void> updateBuilding(
    Directory originalDir,
    String newName,
    String? newIconType,
    dynamic newIconData, {
    String? newImagePath,
  }) async {
    Directory currentDir = originalDir;

    // 1. Rename Folder jika nama berubah
    if (newName != p.basename(originalDir.path)) {
      final newPath = p.join(originalDir.parent.path, newName);
      currentDir = await originalDir.rename(newPath);
    }

    // 2. Baca JSON Lama
    final jsonFile = File(p.join(currentDir.path, 'data.json'));
    Map<String, dynamic> jsonData = {"rooms": [], "plans": []};
    if (await jsonFile.exists()) {
      try {
        jsonData = json.decode(await jsonFile.readAsString());
      } catch (_) {}
    }

    // 3. Handle Gambar
    String? finalIconData = newIconData;
    String? oldImageName;
    if (jsonData['icon_type'] == 'image') oldImageName = jsonData['icon_data'];

    if (newIconType == 'image' && newImagePath != null) {
      final extension = p.extension(newImagePath);
      final uniqueIconName =
          'icon_${DateTime.now().millisecondsSinceEpoch}$extension';
      finalIconData = uniqueIconName;
      await File(newImagePath).copy(p.join(currentDir.path, uniqueIconName));
    } else if (newIconType == 'image' && newImagePath == null) {
      // Pertahankan gambar lama jika user tidak memilih gambar baru tapi tipe tetap image
      finalIconData = oldImageName;
    }

    // Hapus gambar lama jika tidak terpakai
    if (oldImageName != null &&
        (newIconType != 'image' || (finalIconData != oldImageName))) {
      final oldFile = File(p.join(currentDir.path, oldImageName));
      if (await oldFile.exists()) await oldFile.delete();
    }

    // 4. Simpan JSON
    jsonData['icon_type'] = newIconType;
    jsonData['icon_data'] = finalIconData;
    await jsonFile.writeAsString(json.encode(jsonData));
  }

  // --- Delete ---
  Future<void> deleteBuilding(Directory buildingDir) async {
    await buildingDir.delete(recursive: true);
  }

  // --- Helper: Get Icon Data ---
  Future<Map<String, dynamic>> getBuildingIconData(
    Directory buildingDir,
  ) async {
    try {
      final jsonFile = File(p.join(buildingDir.path, 'data.json'));
      // Default standard jika tidak ditemukan
      if (!await jsonFile.exists())
        return {'type': null, 'data': null, 'buildingType': 'standard'};

      final content = await jsonFile.readAsString();
      final data = json.decode(content);

      final iconType = data['icon_type'];
      final iconData = data['icon_data'];
      final buildingType = data['type'] ?? 'standard'; // Ambil tipe bangunan

      Map<String, dynamic> result = {
        'type': iconType,
        'data': iconData,
        'buildingType': buildingType,
      };

      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(buildingDir.path, iconData.toString()));
        if (await imageFile.exists()) {
          result['file'] = imageFile;
          result['type'] = 'image'; // Pastikan tipe konsisten
        } else {
          result['type'] = null;
        }
      }
      return result;
    } catch (e) {
      return {'type': null, 'data': null, 'buildingType': 'standard'};
    }
  }

  // --- Helper: Remove from Map Data (saat dipindah/dihapus) ---
  Future<void> removeBuildingFromMapData(String buildingFolderName) async {
    try {
      final jsonFile = File(
        p.join(districtDirectory.path, 'district_data.json'),
      );
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final data = json.decode(content);
        List<dynamic> placements = data['building_placements'] ?? [];
        placements.removeWhere(
          (item) => item['building_folder_name'] == buildingFolderName,
        );
        data['building_placements'] = placements;
        await jsonFile.writeAsString(json.encode(data));
      }
    } catch (e) {
      print("Warning: Gagal membersihkan data peta: $e");
    }
  }

  // --- Helper: Warehouse / Retract ---
  Future<void> retractToWarehouse(Directory buildingDir) async {
    if (AppSettings.baseBuildingsPath == null)
      throw Exception("Base path not set");

    final warehouseDir = Directory(
      p.join(AppSettings.baseBuildingsPath!, '_BUILDING_WAREHOUSE_'),
    );
    if (!await warehouseDir.exists()) await warehouseDir.create();

    final String name = p.basename(buildingDir.path);
    String newName = name;
    if (await Directory(p.join(warehouseDir.path, name)).exists()) {
      newName = "${name}_${DateTime.now().millisecondsSinceEpoch}";
    }

    await buildingDir.rename(p.join(warehouseDir.path, newName));
    await removeBuildingFromMapData(name);
  }

  // --- LOGIKA BARU: MANAJEMEN MULTI-DENAH ---

  // 1. Ambil Daftar Denah (dengan migrasi otomatis untuk plan lama)
  Future<List<Map<String, dynamic>>> getBuildingPlans(
    Directory buildingDir,
  ) async {
    final jsonFile = File(p.join(buildingDir.path, 'data.json'));
    Map<String, dynamic> data = {};

    if (await jsonFile.exists()) {
      try {
        data = json.decode(await jsonFile.readAsString());
      } catch (_) {}
    }

    // Migrasi: Jika belum ada list 'plans', tapi ada file 'plan.json' lama
    List<dynamic> plans = data['plans'] ?? [];

    if (plans.isEmpty) {
      final oldPlanFile = File(p.join(buildingDir.path, 'plan.json'));
      if (await oldPlanFile.exists()) {
        // Masukkan plan lama sebagai entri pertama
        plans.add({
          'id': 'main',
          'name': 'Denah Utama',
          'filename': 'plan.json',
          'icon': Icons.map.codePoint,
        });

        data['plans'] = plans;
        await jsonFile.writeAsString(json.encode(data));
      }
    }

    return List<Map<String, dynamic>>.from(plans);
  }

  // 2. Tambah Denah Baru ke Bangunan
  Future<void> addPlanToBuilding(
    Directory buildingDir,
    String name,
    int iconCodePoint,
  ) async {
    final jsonFile = File(p.join(buildingDir.path, 'data.json'));
    if (!await jsonFile.exists()) return;

    final content = await jsonFile.readAsString();
    final data = json.decode(content);
    List<dynamic> plans = data['plans'] ?? [];

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final filename = 'plan_$newId.json';

    // Buat file denah kosong baru
    final planFile = File(p.join(buildingDir.path, filename));
    // Struktur awal denah kosong
    await planFile.writeAsString(
      json.encode({
        'floors': [
          {'id': 'main', 'name': name},
        ],
        'activeIdx': 0,
        'cc': Colors.white.value,
      }),
    );

    plans.add({
      'id': newId,
      'name': name,
      'filename': filename,
      'icon': iconCodePoint,
    });

    data['plans'] = plans;
    await jsonFile.writeAsString(json.encode(data));
  }

  // 3. Update Info Denah (Nama/Icon)
  Future<void> updatePlanInfo(
    Directory buildingDir,
    String planId,
    String newName,
    int newIcon,
  ) async {
    final jsonFile = File(p.join(buildingDir.path, 'data.json'));
    if (!await jsonFile.exists()) return;

    final data = json.decode(await jsonFile.readAsString());
    List<dynamic> plans = data['plans'] ?? [];

    final index = plans.indexWhere((p) => p['id'] == planId);
    if (index != -1) {
      plans[index]['name'] = newName;
      plans[index]['icon'] = newIcon;
      data['plans'] = plans;
      await jsonFile.writeAsString(json.encode(data));
    }
  }

  // 4. Hapus Denah
  Future<void> deletePlan(
    Directory buildingDir,
    String planId,
    String filename,
  ) async {
    final jsonFile = File(p.join(buildingDir.path, 'data.json'));
    if (!await jsonFile.exists()) return;

    final data = json.decode(await jsonFile.readAsString());
    List<dynamic> plans = data['plans'] ?? [];

    // Hapus dari list
    plans.removeWhere((p) => p['id'] == planId);
    data['plans'] = plans;
    await jsonFile.writeAsString(json.encode(data));

    // Hapus filenya
    final file = File(p.join(buildingDir.path, filename));
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 5. Reorder (Geser urutan)
  Future<void> reorderPlans(
    Directory buildingDir,
    int oldIndex,
    int newIndex,
  ) async {
    final jsonFile = File(p.join(buildingDir.path, 'data.json'));
    if (!await jsonFile.exists()) return;

    final data = json.decode(await jsonFile.readAsString());
    List<dynamic> plans = data['plans'] ?? [];

    if (oldIndex < plans.length && newIndex <= plans.length) {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = plans.removeAt(oldIndex);
      plans.insert(newIndex, item);

      data['plans'] = plans;
      await jsonFile.writeAsString(json.encode(data));
    }
  }
}
