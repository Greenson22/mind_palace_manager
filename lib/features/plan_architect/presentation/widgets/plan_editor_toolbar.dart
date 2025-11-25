// lib/features/plan_architect/presentation/widgets/plan_editor_toolbar.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/plan_models.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart';
import '../dialogs/shape_picker_sheet.dart'; // IMPORT SHEET BARU

class PlanEditorToolbar extends StatelessWidget {
  final PlanController controller;

  const PlanEditorToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconButton(
                  context,
                  icon: Icons.undo,
                  onTap: controller.canUndo ? controller.undo : null,
                  tooltip: "Undo",
                ),
                _buildIconButton(
                  context,
                  icon: Icons.redo,
                  onTap: controller.canRedo ? controller.redo : null,
                  tooltip: "Redo",
                ),
                _buildDivider(context),

                _buildToolBtn(
                  context,
                  icon: Icons.pan_tool_alt,
                  label: "Geser",
                  isActive: controller.activeTool == PlanTool.hand,
                  onTap: () => controller.setTool(PlanTool.hand),
                ),
                _buildToolBtn(
                  context,
                  icon: Icons.near_me,
                  label: "Pilih",
                  isActive: controller.activeTool == PlanTool.select,
                  onTap: () => controller.setTool(PlanTool.select),
                ),

                _buildIconButton(
                  context,
                  icon: Icons.select_all,
                  tooltip: "Pilih Semua (Select All)",
                  onTap: () {
                    controller.setTool(PlanTool.select);
                    controller.selectAll();
                  },
                ),

                _buildIconButton(
                  context,
                  icon: Icons.checklist,
                  tooltip: "Multi Select Mode",
                  isActive: controller.isMultiSelectMode,
                  onTap: controller.toggleMultiSelectMode,
                  color: controller.isMultiSelectMode ? Colors.orange : null,
                ),

                if (controller.isMultiSelectMode &&
                    controller.multiSelectedIds.isNotEmpty)
                  _buildIconButton(
                    context,
                    icon: Icons.group_work,
                    tooltip: "Buat Grup",
                    onTap: controller.createGroupFromSelection,
                    color: Colors.green,
                  ),

                // --- TOMBOL AI GENERATOR ---
                InkWell(
                  onTap: () => PlanEditorDialogs.showAiPlanGenerator(
                    context,
                    controller,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.purple,
                          size: 20,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "AI Gen",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // -----------------------
                _buildToolBtn(
                  context,
                  icon: Icons.grid_view,
                  label: "Tembok",
                  isActive: controller.activeTool == PlanTool.wall,
                  onTap: () => controller.setTool(PlanTool.wall),
                ),

                _buildToolBtn(
                  context,
                  icon: Icons.door_sliding_outlined,
                  label: "Pintu",
                  isActive: controller.activeTool == PlanTool.door,
                  onTap: () => controller.setTool(PlanTool.door),
                ),
                _buildToolBtn(
                  context,
                  icon: Icons.window_outlined,
                  label: "Jendela",
                  isActive: controller.activeTool == PlanTool.window,
                  onTap: () => controller.setTool(PlanTool.window),
                ),

                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (c) => DraggableScrollableSheet(
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.9,
                        builder: (context, scrollController) {
                          return ShapePickerSheet(controller: controller);
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: _buildToolBtn(
                    context,
                    icon: Icons.category,
                    label: "Bentuk",
                    isActive: controller.activeTool == PlanTool.shape,
                    onTap: null,
                  ),
                ),

                InkWell(
                  onTap: () =>
                      PlanEditorDialogs.showInteriorPicker(context, controller),
                  borderRadius: BorderRadius.circular(8),
                  child: _buildToolBtn(
                    context,
                    icon: controller.selectedObjectIcon ?? Icons.chair,
                    label: "Interior",
                    isActive: controller.activeTool == PlanTool.object,
                    onTap: null,
                  ),
                ),

                _buildToolBtn(
                  context,
                  icon: Icons.text_fields,
                  label: "Teks",
                  isActive: controller.activeTool == PlanTool.text,
                  onTap: () => controller.setTool(PlanTool.text),
                ),

                _buildToolBtn(
                  context,
                  icon: Icons.brush,
                  label: "Gambar",
                  isActive: controller.activeTool == PlanTool.freehand,
                  onTap: () => controller.setTool(PlanTool.freehand),
                ),

                _buildDivider(context),

                _buildIconButton(
                  context,
                  icon: controller.enableSnap ? Icons.grid_on : Icons.grid_off,
                  color: controller.enableSnap ? colorScheme.primary : null,
                  onTap: controller.toggleSnap,
                  tooltip: "Snap to Grid",
                ),
                _buildIconButton(
                  context,
                  icon: Icons.delete_outline,
                  color: controller.activeTool == PlanTool.eraser
                      ? colorScheme.error
                      : null,
                  isActive: controller.activeTool == PlanTool.eraser,
                  onTap: () => controller.setTool(PlanTool.eraser),
                  tooltip: "Penghapus",
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => PlanEditorDialogs.showColorPicker(
                  context,
                  (c) => controller.setActiveColor(c),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: controller.activeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Warna",
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.line_weight,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(
                width: 120,
                height: 20,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: controller.activeStrokeWidth,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: controller.activeStrokeWidth.round().toString(),
                    onChanged: (v) => controller.setActiveStrokeWidth(v),
                  ),
                ),
              ),
              Text(
                "${controller.activeStrokeWidth.toInt()}px",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: Theme.of(context).dividerColor,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
    bool isActive = false,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor =
        color ??
        (isActive ? colorScheme.primary : colorScheme.onSurfaceVariant);
    final bgColor = isActive
        ? colorScheme.primaryContainer
        : Colors.transparent;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildToolBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final fgColor = isActive
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    final bgColor = isActive ? colorScheme.primary : Colors.transparent;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: fgColor,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
