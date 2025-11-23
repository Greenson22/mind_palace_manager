import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/plan_painter.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart';

class PlanCanvasView extends StatelessWidget {
  final PlanController controller;
  final Function(String planId)? onNavigate;

  const PlanCanvasView({super.key, required this.controller, this.onNavigate});

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

  void _handleLongPress(BuildContext context, Offset localPos) {
    if (controller.isViewMode && onNavigate != null) {
      final hitItem = controller.findNavigableItemAt(localPos);
      if (hitItem != null) {
        onNavigate!(hitItem['targetPlanId']!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHand = controller.activeTool == PlanTool.hand;
    final bool isView = controller.isViewMode;
    final bool allowPan = isHand || isView;

    // Ambil setting dinamis dari AppSettings
    final double blurSigma = AppSettings.planBackgroundBlur;
    final double overlayOpacity = AppSettings.planBackgroundOpacity;
    final double scaleMultiplier = AppSettings.planBackgroundScale;

    return Stack(
      children: [
        // 1. BACKGROUND: DYNAMIC BLURRED PLAN
        Positioned.fill(
          child: Stack(
            children: [
              // A. Base Hitam
              Container(color: const Color(0xFF121212)),

              // B. Denah Background (Scaled)
              // Hanya render jika blur > 0 atau opacity tidak penuh
              if (blurSigma > 0 || overlayOpacity < 1.0)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Hitung scale dasar agar cover layar
                      final double scaleX =
                          constraints.maxWidth / controller.canvasWidth;
                      final double scaleY =
                          constraints.maxHeight / controller.canvasHeight;

                      // Scale dasar dikali dengan multiplier dari setting
                      final double finalScale =
                          math.max(scaleX, scaleY) * scaleMultiplier;

                      return Transform.scale(
                        scale: finalScale,
                        alignment: Alignment.center,
                        child: Center(
                          child: SizedBox(
                            width: controller.canvasWidth,
                            height: controller.canvasHeight,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: PlanPainter(controller: controller),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // C. Efek Blur dan Overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(overlayOpacity),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. INTERACTIVE VIEWER (FOREGROUND)
        InteractiveViewer(
          transformationController: controller.transformController,
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
              onLongPressStart: (d) =>
                  _handleLongPress(context, d.localPosition),
              child: Container(
                width: controller.canvasWidth,
                height: controller.canvasHeight,
                decoration: BoxDecoration(
                  color: controller.canvasColor,
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
              if (controller.showZoomButtons) ...[
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
              ],
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
