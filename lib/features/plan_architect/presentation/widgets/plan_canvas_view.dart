// lib/features/plan_architect/presentation/widgets/plan_canvas_view.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/plan_painter.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart';

class PlanCanvasView extends StatelessWidget {
  final PlanController controller;

  const PlanCanvasView({super.key, required this.controller});

  void _handleTapUp(BuildContext context, Offset localPos) {
    if (controller.activeTool == PlanTool.text && !controller.isViewMode) {
      final textCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Tambah Label"),
          content: TextField(
            controller: textCtrl,
            decoration: const InputDecoration(hintText: "Nama Ruangan"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (textCtrl.text.isNotEmpty)
                  controller.addLabel(localPos, textCtrl.text);
                Navigator.pop(ctx);
              },
              child: const Text("Tambah"),
            ),
          ],
        ),
      );
    } else {
      controller.onTapUp(localPos);
      if (controller.isViewMode && controller.selectedId != null) {
        final data = controller.getSelectedItemData();
        if (data != null) PlanEditorDialogs.showViewModeInfo(context, data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHand = controller.activeTool == PlanTool.hand;
    final bool isView = controller.isViewMode;
    final bool allowPan = isHand || isView;

    return Stack(
      children: [
        // 1. BACKGROUND LUAR: HITAM (VOID)
        // Sesuai permintaan: "diluar grid itu bgnya hitam"
        Positioned.fill(
          child: Container(
            color: const Color(0xFF121212),
          ), // Hampir hitam pekat
        ),

        // 2. INTERACTIVE VIEWER (PAN/ZOOM)
        InteractiveViewer(
          transformationController: controller.transformController,
          // Boundary besar agar canvas 500x500 bisa digeser bebas
          boundaryMargin: const EdgeInsets.all(double.infinity),

          panEnabled: allowPan,
          scaleEnabled: allowPan,
          minScale: 0.1,
          maxScale: 5.0,

          child: Center(
            child: GestureDetector(
              onPanStart: allowPan
                  ? null
                  : (d) => controller.onPanStart(d.localPosition),
              onPanUpdate: allowPan
                  ? null
                  : (d) => controller.onPanUpdate(d.localPosition),
              onPanEnd: allowPan ? null : (d) => controller.onPanEnd(),
              onTapUp: (d) => _handleTapUp(context, d.localPosition),

              // 3. KANVAS (KERTAS)
              child: Container(
                width: controller.canvasWidth,
                height: controller.canvasHeight,
                decoration: BoxDecoration(
                  color:
                      controller.canvasColor, // Warna kertas (biasanya putih)
                  // Tambahkan shadow agar batas antara Kertas dan Void Hitam terlihat jelas
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: PlanPainter(controller: controller),
                  size: Size(controller.canvasWidth, controller.canvasHeight),
                ),
              ),
            ),
          ),
        ),

        // 4. TOMBOL ZOOM (KANAN ATAS)
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: "zi",
                onPressed: controller.zoomIn,
                backgroundColor: Colors.white,
                child: const Icon(Icons.add, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "zo",
                onPressed: controller.zoomOut,
                backgroundColor: Colors.white,
                child: const Icon(Icons.remove, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "zr",
                onPressed: controller.resetZoom,
                backgroundColor: Colors.white,
                tooltip: "Reset Zoom",
                child: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
