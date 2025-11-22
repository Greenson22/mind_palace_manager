import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import '../logic/plan_controller.dart';
import 'plan_painter.dart';
import 'dialogs/plan_editor_dialogs.dart';
import 'widgets/plan_editor_toolbar.dart';
import 'widgets/plan_selection_bar.dart';
import 'widgets/plan_canvas_view.dart';

class PlanEditorPage extends StatefulWidget {
  const PlanEditorPage({super.key});

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  final PlanController _controller = PlanController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportImage() async {
    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Atur folder export di Pengaturan dulu.")),
      );
      return;
    }
    try {
      final recorder = ui.PictureRecorder();
      final exportSize = Size(
        _controller.canvasWidth,
        _controller.canvasHeight,
      );
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
        Paint()..color = _controller.canvasColor,
      );
      final painter = PlanPainter(controller: _controller);
      painter.paint(canvas, exportSize);
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        exportSize.width.toInt(),
        exportSize.height.toInt(),
      );
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes != null) {
        final now = DateTime.now();
        final fileName =
            'plan_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.png';
        final file = File(p.join(AppSettings.exportPath!, fileName));
        await file.writeAsBytes(pngBytes.buffer.asUint8List());
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Disimpan: ${file.path}"),
              backgroundColor: Colors.green,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bool isView = _controller.isViewMode;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  isView ? "Mode Lihat" : "Arsitek Denah",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  _controller.activeFloor.name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            backgroundColor: isView ? Colors.white : null,
            elevation: isView ? 1 : 4,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.layers),
                label: const Text("Lantai"),
                onPressed: () =>
                    PlanEditorDialogs.showFloorManager(context, _controller),
              ),
              IconButton(
                icon: Icon(isView ? Icons.edit : Icons.visibility),
                tooltip: isView ? "Kembali ke Edit" : "Mode Presentasi",
                onPressed: _controller.toggleViewMode,
              ),
              IconButton(
                icon: const Icon(Icons.settings_display),
                tooltip: "Layer & Tampilan",
                onPressed: () =>
                    PlanEditorDialogs.showLayerSettings(context, _controller),
              ),
              if (!isView) ...[
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: "Export",
                  onPressed: _exportImage,
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'clear') _controller.clearAll();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'clear',
                      child: Text(
                        'Hapus Semua',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              if (!isView) PlanEditorToolbar(controller: _controller),
              if (!isView && _controller.selectedId != null)
                PlanSelectionBar(controller: _controller),
              if (!isView && _controller.activeTool == PlanTool.eraser)
                Container(
                  color: Colors.red.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Mode Penghapus Aktif",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (!isView && _controller.activeTool == PlanTool.text)
                Container(
                  color: Colors.orange.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Ketuk di layar untuk menambah teks",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              Expanded(child: PlanCanvasView(controller: _controller)),
            ],
          ),
        );
      },
    );
  }
}
