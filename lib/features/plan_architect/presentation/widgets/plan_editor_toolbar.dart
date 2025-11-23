// lib/features/plan_architect/presentation/widgets/plan_editor_toolbar.dart
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
      constraints: const BoxConstraints(
        maxWidth: 600,
      ), // Batasi lebar di tablet
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // BARIS 1: ALAT UTAMA
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group: History
                _buildIconButton(
                  icon: Icons.undo,
                  onTap: controller.canUndo ? controller.undo : null,
                  tooltip: "Undo",
                ),
                _buildIconButton(
                  icon: Icons.redo,
                  onTap: controller.canRedo ? controller.redo : null,
                  tooltip: "Redo",
                ),
                _buildDivider(),

                // Group: Tools
                _buildToolBtn(
                  icon: Icons.pan_tool_alt, // Hand tool
                  label: "Geser",
                  isActive: controller.activeTool == PlanTool.hand,
                  onTap: () => controller.setTool(PlanTool.hand),
                ),

                // --- PERUBAHAN 6: TOMBOL BARU GESER SEMUA ---
                _buildToolBtn(
                  icon: Icons.transform,
                  label: "Geser Isi",
                  isActive: controller.activeTool == PlanTool.moveAll,
                  onTap: () => controller.setTool(PlanTool.moveAll),
                ),

                // ---------------------------------------------
                _buildToolBtn(
                  icon: Icons.near_me, // Select cursor
                  label: "Pilih",
                  isActive: controller.activeTool == PlanTool.select,
                  onTap: () => controller.setTool(PlanTool.select),
                ),
                _buildToolBtn(
                  icon: Icons.grid_view, // Wall tool
                  label: "Tembok",
                  isActive: controller.activeTool == PlanTool.wall,
                  onTap: () => controller.setTool(PlanTool.wall),
                ),

                // Group: Objects & Shapes
                PopupMenuButton<PlanShapeType>(
                  tooltip: "Pilih Bentuk",
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildToolBtn(
                    icon: Icons.category,
                    label: "Bentuk",
                    isActive: controller.activeTool == PlanTool.shape,
                    onTap: null, // Trigger menu
                  ),
                  onSelected: (type) => controller.selectShape(type),
                  itemBuilder: (ctx) => [
                    _buildPopupItem(
                      PlanShapeType.rectangle,
                      Icons.crop_square,
                      "Kotak",
                    ),
                    _buildPopupItem(
                      PlanShapeType.circle,
                      Icons.circle_outlined,
                      "Bulat",
                    ),
                    _buildPopupItem(
                      PlanShapeType.star,
                      Icons.star_border,
                      "Bintang",
                    ),
                  ],
                ),

                InkWell(
                  onTap: () =>
                      PlanEditorDialogs.showInteriorPicker(context, controller),
                  borderRadius: BorderRadius.circular(8),
                  child: _buildToolBtn(
                    icon: controller.selectedObjectIcon ?? Icons.chair,
                    label: "Interior",
                    isActive: controller.activeTool == PlanTool.object,
                    onTap: null, // Trigger bottom sheet via InkWell
                  ),
                ),

                _buildToolBtn(
                  icon: Icons.text_fields,
                  label: "Teks",
                  isActive: controller.activeTool == PlanTool.text,
                  onTap: () => controller.setTool(PlanTool.text),
                ),

                _buildToolBtn(
                  icon: Icons.brush,
                  label: "Gambar",
                  isActive: controller.activeTool == PlanTool.freehand,
                  onTap: () => controller.setTool(PlanTool.freehand),
                ),

                _buildDivider(),

                // Group: Actions
                _buildIconButton(
                  icon: controller.enableSnap ? Icons.grid_on : Icons.grid_off,
                  color: controller.enableSnap ? Colors.blue : Colors.grey,
                  onTap: controller.toggleSnap,
                  tooltip: "Snap to Grid",
                ),
                _buildIconButton(
                  icon: Icons.delete_outline,
                  color: controller.activeTool == PlanTool.eraser
                      ? Colors.red
                      : Colors.grey,
                  isActive: controller.activeTool == PlanTool.eraser,
                  onTap: () => controller.setTool(PlanTool.eraser),
                  tooltip: "Penghapus",
                ),
              ],
            ),
          ),

          // BARIS 2: ATRIBUT (Warna & Ukuran)
          // Hanya muncul jika tool relevan aktif (opsional, di sini kita tampilkan terus tapi lebih kecil)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Color Picker Indicator
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
                      const Text("Warna", style: TextStyle(fontSize: 10)),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Stroke Slider
              const Icon(Icons.line_weight, size: 16, color: Colors.grey),
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
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
    bool isActive = false,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? Colors.blue : (color ?? Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildToolBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<PlanShapeType> _buildPopupItem(
    PlanShapeType value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
