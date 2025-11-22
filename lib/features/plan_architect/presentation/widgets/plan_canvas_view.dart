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

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: controller.transformController,
          // Boundary margin besar agar canvas bisa digeser bebas
          boundaryMargin: const EdgeInsets.all(2000),
          panEnabled: isHand || isView,
          scaleEnabled: isHand || isView,
          minScale: 0.1,
          maxScale: 5.0,
          child: GestureDetector(
            onPanStart: (d) => controller.onPanStart(d.localPosition),
            onPanUpdate: (d) => controller.onPanUpdate(d.localPosition),
            onPanEnd: (d) => controller.onPanEnd(),
            onTapUp: (d) => _handleTapUp(context, d.localPosition),
            child: Container(
              width: controller.canvasWidth,
              height: controller.canvasHeight,
              decoration: BoxDecoration(
                color: controller.canvasColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
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

        // Tombol Zoom dipindah ke KANAN ATAS (Top Right)
        // Agar tidak menghalangi toolbar di bawah
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
