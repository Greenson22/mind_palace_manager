import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/permission_helper.dart';

class WorldRegionLogic {
  // Load daftar region
  Future<List<Directory>> loadRegions() async {
    bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) throw Exception("Izin penyimpanan ditolak.");

    if (AppSettings.baseBuildingsPath == null) {
      throw Exception("Path utama belum diatur.");
    }

    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    if (!await rootDir.exists()) {
      await rootDir.create(recursive: true);
    }

    final entities = await rootDir.list().toList();
    return entities
        .whereType<Directory>()
        .where((d) => p.basename(d.path) != '_BUILDING_WAREHOUSE_')
        .toList();
  }

  // Buat region baru
  Future<void> createRegion(String name) async {
    if (AppSettings.baseBuildingsPath == null) return;

    final newRegionPath = p.join(AppSettings.baseBuildingsPath!, name);
    final newDir = Directory(newRegionPath);

    if (await newDir.exists()) throw Exception("Nama wilayah sudah ada.");

    await newDir.create(recursive: true);

    final dataJsonFile = File(p.join(newRegionPath, 'region_data.json'));
    await dataJsonFile.writeAsString(
      json.encode({
        "map_image": null,
        "district_placements": [],
        "icon_type": null,
        "icon_data": null,
      }),
    );
  }

  // Update region (Rename / Ganti Icon)
  Future<void> updateRegion(
    Directory originalDir,
    String newName,
    String? newIconType,
    dynamic newIconData, {
    String? newImagePath,
  }) async {
    Directory currentDir = originalDir;

    // 1. Rename Folder
    if (newName != p.basename(originalDir.path)) {
      final newPath = p.join(originalDir.parent.path, newName);
      currentDir = await originalDir.rename(newPath);
    }

    // 2. Handle Logic Icon Image (Copy file jika baru)
    String? finalIconData = newIconData;
    if (newIconType == 'image' && newImagePath != null) {
      // Jika user upload gambar baru dari picker
      if (!newImagePath.startsWith('MAP_IMAGE_REF:')) {
        final extension = p.extension(newImagePath);
        final uniqueName = 'region_icon$extension'; // Fixed name for icon
        finalIconData = uniqueName;
        await File(newImagePath).copy(p.join(currentDir.path, uniqueName));
      }
    }

    // 3. Update JSON
    final jsonFile = File(p.join(currentDir.path, 'region_data.json'));
    Map<String, dynamic> jsonData = {};
    if (await jsonFile.exists()) {
      jsonData = json.decode(await jsonFile.readAsString());
    }

    jsonData['icon_type'] = newIconType;
    jsonData['icon_data'] = finalIconData;

    await jsonFile.writeAsString(json.encode(jsonData));
  }

  // Hapus region
  Future<void> deleteRegion(Directory regionDir) async {
    await regionDir.delete(recursive: true);
  }

  // Ambil data ikon untuk list
  Future<Map<String, dynamic>> getRegionIconData(Directory regionDir) async {
    try {
      final jsonFile = File(p.join(regionDir.path, 'region_data.json'));
      if (!await jsonFile.exists()) return {'type': null, 'data': null};

      final content = await jsonFile.readAsString();
      final data = json.decode(content);

      if (data['icon_type'] == 'image' && data['icon_data'] != null) {
        final imageFile = File(
          p.join(regionDir.path, data['icon_data'].toString()),
        );
        if (await imageFile.exists()) {
          return {
            'type': 'image',
            'data': data['icon_data'],
            'file': imageFile,
          };
        }
      }
      return {'type': data['icon_type'], 'data': data['icon_data']};
    } catch (e) {
      return {'type': null, 'data': null};
    }
  }

  // Cek apakah region punya peta (untuk opsi "Gunakan Peta")
  Future<String?> getRegionMapImageName(Directory regionDir) async {
    try {
      final jsonFile = File(p.join(regionDir.path, 'region_data.json'));
      if (await jsonFile.exists()) {
        final data = json.decode(await jsonFile.readAsString());
        return data['map_image'];
      }
    } catch (_) {}
    return null;
  }
}
