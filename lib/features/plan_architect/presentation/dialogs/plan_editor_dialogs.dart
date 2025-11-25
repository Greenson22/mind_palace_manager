import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/interior_picker_sheet.dart';

// --- IMPORTS DARI FOLDER SUB ---
import 'sub/plan_layer_settings.dart';
import 'sub/plan_item_editor.dart';
import 'sub/plan_transforms.dart';
import 'sub/plan_view_info.dart';
import 'sub/plan_ai_generator.dart';

class PlanEditorDialogs {
  /// Menampilkan pengaturan layer (Grid, Tembok, dll)
  static void showLayerSettings(
    BuildContext context,
    PlanController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => PlanLayerSettingsDialog(controller: controller),
    );
  }

  /// Menampilkan dialog edit atribut item (Nama, Deskripsi, Ukuran, Gambar)
  static void showEditDialog(
    BuildContext context,
    PlanController controller, {
    Directory? buildingDirectory,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PlanItemEditorDialog(
        controller: controller,
        buildingDirectory: buildingDirectory,
      ),
    );
  }

  /// Menampilkan Color Picker
  static void showColorPicker(
    BuildContext context,
    Function(Color) onColorSelected,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => PlanColorPickerDialog(onColorSelected: onColorSelected),
    );
  }

  /// Menampilkan Interior Picker Sheet (Wrapper)
  static void showInteriorPicker(
    BuildContext context,
    PlanController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return InteriorPickerSheet(
              controller: controller,
              scrollController: scrollController,
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  /// Menampilkan Info Item saat Mode Lihat (View Mode)
  static void showViewModeInfo(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => PlanViewInfoSheet(data: data),
    );
  }

  /// Menampilkan Dialog Rotasi Detail
  static void showRotationDialog(
    BuildContext context,
    double currentRotationRadians,
    Function(double) onRotationChanged,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => PlanRotationDialog(
        currentRotationRadians: currentRotationRadians,
        onRotationChanged: onRotationChanged,
      ),
    );
  }

  /// Menampilkan Dialog AI Generator
  static void showAiPlanGenerator(
    BuildContext context,
    PlanController controller,
  ) {
    showDialog(
      context: context,
      builder: (c) => PlanAiGeneratorDialog(controller: controller),
    );
  }
}
