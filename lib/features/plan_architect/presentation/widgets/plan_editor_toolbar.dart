import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/plan_models.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart';

class PlanEditorToolbar extends StatelessWidget {
  final PlanController controller;

  const PlanEditorToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    controller.enableSnap ? Icons.grid_on : Icons.grid_off,
                    color: Colors.grey,
                  ),
                  onPressed: controller.toggleSnap,
                  tooltip: "Snap",
                ),
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.grey),
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo, color: Colors.grey),
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
                const VerticalDivider(width: 20, thickness: 1),
                _buildToolBtn(
                  icon: Icons.pan_tool_alt,
                  label: "Geser",
                  isActive: controller.activeTool == PlanTool.hand,
                  onTap: () => controller.setTool(PlanTool.hand),
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.pan_tool,
                  label: "Pilih",
                  isActive: controller.activeTool == PlanTool.select,
                  onTap: () => controller.setTool(PlanTool.select),
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.format_paint,
                  label: "Tembok",
                  isActive: controller.activeTool == PlanTool.wall,
                  onTap: () => controller.setTool(PlanTool.wall),
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.text_fields,
                  label: "Teks",
                  isActive: controller.activeTool == PlanTool.text,
                  onTap: () => controller.setTool(PlanTool.text),
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.brush,
                  label: "Gambar",
                  isActive: controller.activeTool == PlanTool.freehand,
                  onTap: () => controller.setTool(PlanTool.freehand),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<PlanShapeType>(
                  child: _buildToolBtn(
                    icon: Icons.category,
                    label: "Bentuk",
                    isActive: controller.activeTool == PlanTool.shape,
                    onTap: null,
                  ),
                  onSelected: (type) => controller.selectShape(type),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: PlanShapeType.rectangle,
                      child: Text("Kotak"),
                    ),
                    const PopupMenuItem(
                      value: PlanShapeType.circle,
                      child: Text("Bulat"),
                    ),
                    const PopupMenuItem(
                      value: PlanShapeType.star,
                      child: Text("Bintang"),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () =>
                      PlanEditorDialogs.showInteriorPicker(context, controller),
                  child: _buildToolBtn(
                    icon: controller.selectedObjectIcon ?? Icons.chair,
                    label: "Interior",
                    isActive: controller.activeTool == PlanTool.object,
                    onTap: null,
                  ),
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.delete_forever,
                  label: "Hapus",
                  isActive: controller.activeTool == PlanTool.eraser,
                  iconColor: Colors.red,
                  onTap: () => controller.setTool(PlanTool.eraser),
                ),
              ],
            ),
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Atribut: ",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              InkWell(
                onTap: () => PlanEditorDialogs.showColorPicker(
                  context,
                  (c) => controller.setActiveColor(c),
                ),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: controller.activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.line_weight, size: 20, color: Colors.grey),
              SizedBox(
                width: 100,
                child: Slider(
                  value: controller.activeStrokeWidth,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  label: controller.activeStrokeWidth.round().toString(),
                  onChanged: (v) => controller.setActiveStrokeWidth(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (iconColor ?? Colors.blueAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : (iconColor ?? Colors.black87),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
