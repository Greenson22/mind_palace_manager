// lib/features/plan_architect/presentation/plan_editor_page.dart
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
      // Gunakan ukuran canvas dari controller (Fixed 5000x5000)
      final exportSize = Size(
        _controller.canvasWidth,
        _controller.canvasHeight,
      );
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
      );

      // Gambar background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
        Paint()..color = _controller.canvasColor,
      );

      // Gambar konten
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _controller.activeFloor.name,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: const Icon(Icons.layers_outlined),
                tooltip: "Kelola Lantai",
                onPressed: () =>
                    PlanEditorDialogs.showFloorManager(context, _controller),
              ),
              IconButton(
                icon: Icon(isView ? Icons.edit : Icons.visibility_outlined),
                tooltip: isView ? "Kembali ke Edit" : "Mode Presentasi",
                onPressed: _controller.toggleViewMode,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'settings') {
                    PlanEditorDialogs.showLayerSettings(context, _controller);
                  } else if (v == 'export') {
                    _exportImage();
                  } else if (v == 'clear') {
                    _controller.clearAll();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_display),
                      title: Text('Tampilan & Ukuran'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  if (!isView) ...[
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.save_alt),
                        title: Text('Export Gambar'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'clear',
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red),
                        title: Text(
                          'Hapus Semua',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              // 1. CANVAS (LAYER PALING BAWAH)
              // Catatan: Tombol Zoom sudah ada di dalam widget PlanCanvasView
              Positioned.fill(child: PlanCanvasView(controller: _controller)),

              // 2. SELECTION BAR (MUNCUL DI ATAS TOOLBAR UTAMA)
              if (!isView && _controller.selectedId != null)
                Positioned(
                  bottom: 100, // Di atas toolbar utama (32 + 60 + padding)
                  left: 16,
                  right: 16,
                  child: PlanSelectionBar(controller: _controller),
                ),

              // 3. TOOLBAR UTAMA (LAYER ATAS, DI BAWAH LAYAR)
              if (!isView)
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: PlanEditorToolbar(controller: _controller),
                  ),
                ),

              // 4. STATUS INDIKATOR (MISAL: ERASER AKTIF)
              if (!isView && _controller.activeTool == PlanTool.eraser)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Mode Penghapus Aktif",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. TEXT HINT
              if (!isView && _controller.activeTool == PlanTool.text)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Ketuk area kosong untuk menambah teks",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
