// lib/features/plan_architect/logic/mixins/plan_image_mixin.dart
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // Import path
import 'plan_variables.dart';
import 'plan_state_mixin.dart';
import '../plan_enums.dart';
import '../../data/plan_models.dart';

mixin PlanImageMixin on PlanVariables, PlanStateMixin {
  Future<ui.Image> loadImageFromFile(String path) async {
    final file = File(path);
    final data = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> reloadImagesForActiveFloor() async {
    List<PlanObject> newObjects = [];
    bool changed = false;

    for (var obj in objects) {
      if (obj.imagePath != null && obj.cachedImage == null) {
        try {
          // --- LOGIKA BARU: Resolve Relative Path ---
          String effectivePath = obj.imagePath!;
          if (buildingDirectory != null && !p.isAbsolute(effectivePath)) {
            effectivePath = p.join(buildingDirectory!.path, effectivePath);
          }
          // ------------------------------------------

          final img = await loadImageFromFile(effectivePath);
          newObjects.add(obj.copyWith(cachedImage: img));
          changed = true;
        } catch (e) {
          // Jika gagal load, biarkan objek tanpa gambar (mungkin placeholder)
          newObjects.add(obj);
        }
      } else {
        newObjects.add(obj);
      }
    }

    if (changed) {
      floors[activeFloorIndex] = activeFloor.copyWith(objects: newObjects);
      notifyListeners();
    }
  }

  Future<void> addCustomImageObject() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      String imagePathToSave = originalPath;
      ui.Image? img;

      // --- LOGIKA BARU: COPY KE FOLDER BANGUNAN ---
      if (buildingDirectory != null) {
        try {
          final ext = p.extension(originalPath);
          final fileName =
              'custom_img_${DateTime.now().millisecondsSinceEpoch}$ext';
          final destPath = p.join(buildingDirectory!.path, fileName);

          // Copy file
          await File(originalPath).copy(destPath);

          // Gunakan nama file (relatif) untuk disimpan di JSON
          imagePathToSave = fileName;

          // Load gambar dari hasil copy untuk memastikan berhasil
          img = await loadImageFromFile(destPath);
        } catch (e) {
          debugPrint("Gagal menyalin gambar interior: $e");
          // Fallback load dari original jika gagal copy
          img = await loadImageFromFile(originalPath);
        }
      } else {
        // Fallback jika tidak ada buildingDirectory (misal mode standalone)
        try {
          img = await loadImageFromFile(originalPath);
        } catch (_) {}
      }
      // -------------------------------------------

      final pos = Offset(canvasWidth / 2, canvasHeight / 2);

      final newObj = PlanObject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: pos,
        name: "Gambar Custom",
        description: "Gambar dari galeri",
        iconCodePoint: Icons.image.codePoint,
        color: Colors.white,
        imagePath:
            imagePathToSave, // Simpan path relatif/absolut sesuai logika di atas
        cachedImage: img,
        size: 50.0,
      );

      updateActiveFloor(objects: [...objects, newObj]);
      saveState();

      activeTool = PlanTool.select;
      selectedId = newObj.id;
      isObjectSelected = true;
      notifyListeners();
    }
  }
}
