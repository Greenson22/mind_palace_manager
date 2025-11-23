// lib/features/plan_architect/logic/mixins/plan_image_mixin.dart
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
      // Jika punya path tapi belum punya cachedImage
      if (obj.imagePath != null && obj.cachedImage == null) {
        try {
          final img = await loadImageFromFile(obj.imagePath!);
          newObjects.add(obj.copyWith(cachedImage: img));
          changed = true;
        } catch (e) {
          newObjects.add(obj);
        }
      } else {
        newObjects.add(obj);
      }
    }

    if (changed) {
      // Update langsung tanpa trigger saveState
      floors[activeFloorIndex] = activeFloor.copyWith(objects: newObjects);
      notifyListeners();
    }
  }

  Future<void> addCustomImageObject() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ui.Image? img;
      try {
        img = await loadImageFromFile(path);
      } catch (_) {}

      // Taruh di tengah
      final pos = Offset(canvasWidth / 2, canvasHeight / 2);

      final newObj = PlanObject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: pos,
        name: "Gambar Custom",
        description: "Gambar dari galeri",
        iconCodePoint: Icons.image.codePoint,
        color: Colors.white,
        imagePath: path,
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
