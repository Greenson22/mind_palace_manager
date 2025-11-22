import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart';

class PlanSelectionBar extends StatelessWidget {
  final PlanController controller;

  const PlanSelectionBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.getSelectedItemData();
    if (data == null) return const SizedBox.shrink();

    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${data['title']} (${data['type']})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => PlanEditorDialogs.showColorPicker(
                  context,
                  (c) => controller.updateSelectedAttribute(color: c),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.color_lens, color: Colors.blue),
                ),
              ),
              if (data['type'] == 'Struktur' || data['type'] == 'Gambar')
                SizedBox(
                  width: 80,
                  child: Slider(
                    value: (data['type'] == 'Struktur')
                        ? (controller.walls
                              .firstWhere((w) => w.id == controller.selectedId)
                              .thickness)
                        : (controller.paths
                              .firstWhere((p) => p.id == controller.selectedId)
                              .strokeWidth),
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    onChanged: (v) => controller.updateSelectedStrokeWidth(v),
                  ),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: const Text("Info"),
                onPressed: () =>
                    PlanEditorDialogs.showEditDialog(context, controller),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const Divider(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: controller.duplicateSelected,
                tooltip: "Duplikat",
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, size: 20),
                onPressed: controller.rotateSelected,
                tooltip: "Putar",
              ),
              IconButton(
                icon: const Icon(Icons.flip_to_front, size: 20),
                onPressed: controller.bringToFront,
                tooltip: "Ke Depan",
              ),
              IconButton(
                icon: const Icon(Icons.flip_to_back, size: 20),
                onPressed: controller.sendToBack,
                tooltip: "Ke Belakang",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
