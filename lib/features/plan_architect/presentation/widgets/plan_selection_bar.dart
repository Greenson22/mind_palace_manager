// lib/features/plan_architect/presentation/widgets/plan_selection_bar.dart
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

    // Helper untuk mendapatkan nilai ukuran saat ini
    double currentSize = 2.0;
    if (data['type'] == 'Struktur') {
      currentSize = controller.walls
          .firstWhere((w) => w.id == controller.selectedId)
          .thickness;
    } else if (data['type'] == 'Gambar') {
      currentSize = controller.paths
          .firstWhere((p) => p.id == controller.selectedId)
          .strokeWidth;
    } else if (data['type'] == 'Interior') {
      currentSize = controller.objects
          .firstWhere((o) => o.id == controller.selectedId)
          .size;
    } else if (data['type'] == 'Label') {
      currentSize = controller.labels
          .firstWhere((l) => l.id == controller.selectedId)
          .fontSize;
    } else if (data['type'] == 'Bentuk') {
      currentSize = 5.0; // Nilai tengah default untuk slider
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Background Putih
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "Objek",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        // --- PERUBAHAN: Paksa warna hitam agar terlihat di bg putih ---
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data['type'] ?? "Item",
                      style: TextStyle(
                        fontSize: 11,
                        // Warna abu-abu gelap
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: const Text("Detail"),
                onPressed: () =>
                    PlanEditorDialogs.showEditDialog(context, controller),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(color: Colors.blue.shade200),
                  // --- PERUBAHAN: Warna teks tombol biru ---
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAction(
                icon: Icons.color_lens,
                label: "Warna",
                onTap: () => PlanEditorDialogs.showColorPicker(
                  context,
                  (c) => controller.updateSelectedAttribute(color: c),
                ),
              ),

              // SLIDER UKURAN
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "Ukuran",
                      // Text caption ukuran
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    SizedBox(
                      height: 20,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                        ),
                        child: Slider(
                          value: currentSize.clamp(1.0, 50.0), // Batas aman
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          onChanged: (v) =>
                              controller.updateSelectedStrokeWidth(v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildQuickAction(
                icon: Icons.copy,
                label: "Salin",
                onTap: controller.duplicateSelected,
              ),
              _buildQuickAction(
                icon: Icons.rotate_right,
                label: "Putar",
                onTap: controller.rotateSelected,
              ),
              _buildQuickAction(
                icon: Icons.layers,
                label: "Urutan",
                onTap: () => _showOrderMenu(context, controller),
              ),
              _buildQuickAction(
                icon: Icons.delete_outline,
                label: "Hapus",
                color: Colors.red,
                onTap: controller.deleteSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderMenu(BuildContext context, PlanController controller) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          onTap: controller.bringToFront,
          child: const Row(
            children: [
              Icon(Icons.flip_to_front),
              SizedBox(width: 8),
              Text("Ke Paling Depan"),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: controller.sendToBack,
          child: const Row(
            children: [
              Icon(Icons.flip_to_back),
              SizedBox(width: 8),
              Text("Ke Paling Belakang"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87, // Default hitam
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }
}
