// lib/features/plan_architect/presentation/widgets/plan_selection_bar.dart
import 'dart:async';
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

    final colorScheme = Theme.of(context).colorScheme;
    bool isGroup = data['isGroup'] ?? false;

    double currentSize = 2.0;
    if (!isGroup) {
      if (data['type'] == 'Struktur') {
        try {
          final wall = controller.walls.firstWhere(
            (w) => w.id == controller.selectedId,
          );
          currentSize = wall.thickness;
        } catch (_) {
          try {
            final portal = controller.portals.firstWhere(
              (p) => p.id == controller.selectedId,
            );
            currentSize = portal.width;
          } catch (e) {
            currentSize = 2.0;
          }
        }
      } else if (data['type'] == 'Gambar') {
        try {
          currentSize = controller.paths
              .firstWhere((p) => p.id == controller.selectedId)
              .strokeWidth;
        } catch (_) {}
      } else if (data['type'] == 'Interior') {
        try {
          currentSize = controller.objects
              .firstWhere((o) => o.id == controller.selectedId)
              .size;
        } catch (_) {}
      } else if (data['type'] == 'Label') {
        try {
          currentSize = controller.labels
              .firstWhere((l) => l.id == controller.selectedId)
              .fontSize;
        } catch (_) {}
      } else if (data['type'] == 'Bentuk') {
        currentSize = 5.0;
      }
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGroup ? Icons.group_work : Icons.touch_app,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "Objek",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data['desc'] ?? data['type'] ?? "Item",
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
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
                  side: BorderSide(color: colorScheme.outline),
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),

          // 2. Ukuran & Warna
          Row(
            children: [
              if (!isGroup)
                _buildQuickAction(
                  context,
                  icon: Icons.color_lens,
                  label: "Warna",
                  onTap: () => PlanEditorDialogs.showColorPicker(
                    context,
                    (c) => controller.updateSelectedAttribute(color: c),
                  ),
                ),
              const SizedBox(width: 8),
              if (!isGroup)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          (data['type'] == 'Struktur' && currentSize > 10)
                              ? "Lebar Objek"
                              : "Ukuran",
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            trackHeight: 2,
                          ),
                          child: Slider(
                            value: currentSize.clamp(1.0, 150.0),
                            min: 1.0,
                            max: 150.0,
                            divisions: 149,
                            onChanged: (v) =>
                                controller.updateSelectedStrokeWidth(v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. PAD PENGGESER (DIRECTIONAL PAD)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Geser:",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                // Menggunakan NudgeButton yang di-update
                _NudgeButton(
                  icon: Icons.chevron_left,
                  onPressed: () =>
                      controller.nudgeSelection(const Offset(-2, 0)),
                  onRelease: controller.saveState, // Simpan state saat dilepas
                ),
                _NudgeButton(
                  icon: Icons.keyboard_arrow_up,
                  onPressed: () =>
                      controller.nudgeSelection(const Offset(0, -2)),
                  onRelease: controller.saveState,
                ),
                _NudgeButton(
                  icon: Icons.keyboard_arrow_down,
                  onPressed: () =>
                      controller.nudgeSelection(const Offset(0, 2)),
                  onRelease: controller.saveState,
                ),
                _NudgeButton(
                  icon: Icons.chevron_right,
                  onPressed: () =>
                      controller.nudgeSelection(const Offset(2, 0)),
                  onRelease: controller.saveState,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Quick Actions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isGroup)
                  _buildQuickAction(
                    context,
                    icon: Icons.group_off,
                    label: "Ungroup",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Ungroup?"),
                          content: const Text(
                            "Grup akan dibubarkan menjadi objek terpisah.",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Batal"),
                              onPressed: () => Navigator.pop(c),
                            ),
                            ElevatedButton(
                              child: const Text("Ya, Ungroup"),
                              onPressed: () {
                                Navigator.pop(c);
                                controller.ungroupSelected();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                if (isGroup || (data['isPath'] == true))
                  _buildQuickAction(
                    context,
                    icon: Icons.bookmark_add,
                    label: "Simpan",
                    onTap: controller.saveCurrentSelectionToLibrary,
                  ),

                _buildQuickAction(
                  context,
                  icon: Icons.copy,
                  label: "Salin",
                  onTap: controller.duplicateSelected,
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.rotate_right,
                  label: "Putar",
                  onTap: controller.rotateSelected,
                ),
                _buildQuickAction(
                  context,
                  icon: Icons.layers,
                  label: "Urutan",
                  onTap: () => _showOrderMenu(context, controller),
                ),

                _buildQuickAction(
                  context,
                  icon: Icons.delete_outline,
                  label: "Hapus",
                  color: colorScheme.error,
                  onTap: () {
                    if (isGroup) {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Hapus Grup?"),
                          content: const Text(
                            "Grup ini beserta isinya akan dihapus permanen.",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Batal"),
                              onPressed: () => Navigator.pop(c),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Hapus"),
                              onPressed: () {
                                Navigator.pop(c);
                                controller.deleteSelected();
                              },
                            ),
                          ],
                        ),
                      );
                    } else {
                      controller.deleteSelected();
                    }
                  },
                ),
              ],
            ),
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

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final finalColor = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: finalColor),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: finalColor)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET TOMBOL GESER (Support Tekan Lama & Simpan State) ---
class _NudgeButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onRelease; // Callback baru

  const _NudgeButton({
    required this.icon,
    required this.onPressed,
    required this.onRelease,
  });

  @override
  State<_NudgeButton> createState() => _NudgeButtonState();
}

class _NudgeButtonState extends State<_NudgeButton> {
  Timer? _timer;

  void _handleTapDown(TapDownDetails details) {
    // Eksekusi sekali saat ditekan
    widget.onPressed();
    // Mulai timer untuk repeat jika ditahan
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      widget.onPressed();
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _stopTimer();
  }

  void _handleTapCancel() {
    _stopTimer();
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      // Panggil save state saat dilepas
      widget.onRelease();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Icon(widget.icon, size: 20),
      ),
    );
  }
}
