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
  // Parameter opsional: jika diisi, editor berjalan dalam mode "Bangunan Denah"
  final Directory? buildingDirectory;

  // --- BARU: Opsi untuk membuka langsung dalam mode lihat ---
  final bool initialViewMode;

  const PlanEditorPage({
    super.key,
    this.buildingDirectory,
    this.initialViewMode = false, // Default false (Edit Mode)
  });

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  final PlanController _controller = PlanController();

  @override
  void initState() {
    super.initState();
    // Jika dibuka dari bangunan, muat file plan.json
    if (widget.buildingDirectory != null) {
      _loadBuildingPlan();
    }

    // --- BARU: Set mode awal ---
    if (widget.initialViewMode) {
      _controller.isViewMode = true;
      _controller.activeTool = PlanTool.select;
    }
  }

  Future<void> _loadBuildingPlan() async {
    final planFile = p.join(widget.buildingDirectory!.path, 'plan.json');
    await _controller.loadFromPath(planFile);
  }

  Future<void> _saveBuildingPlan() async {
    if (widget.buildingDirectory != null) {
      final planFile = p.join(widget.buildingDirectory!.path, 'plan.json');
      await _controller.saveToPath(planFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Denah berhasil disimpan ke bangunan"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

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
        String prefix = "plan";
        // Jika dalam mode bangunan, gunakan nama bangunan sebagai prefix
        if (widget.buildingDirectory != null) {
          prefix = "plan_${p.basename(widget.buildingDirectory!.path)}";
        }

        final fileName =
            '${prefix}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.png';
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

  // Konfirmasi Keluar
  Future<void> _onWillPop(bool didPop) async {
    if (didPop) return;

    if (_controller.hasUnsavedChanges) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Belum Disimpan'),
          content: const Text('Anda memiliki perubahan yang belum disimpan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            // Opsi Simpan & Keluar khusus mode bangunan
            if (widget.buildingDirectory != null)
              TextButton(
                onPressed: () async {
                  await _saveBuildingPlan();
                  if (mounted) Navigator.pop(c, true);
                },
                child: const Text(
                  'Simpan & Keluar',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Keluar Tanpa Simpan'),
            ),
          ],
        ),
      );

      if (shouldPop == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bool isView = _controller.isViewMode;
        final colorScheme = Theme.of(context).colorScheme;

        String title = isView ? "Mode Lihat" : "Arsitek Denah";
        if (widget.buildingDirectory != null) {
          title += " (${p.basename(widget.buildingDirectory!.path)})";
        }

        return PopScope(
          canPop: false,
          onPopInvoked: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16, // Font agak kecil agar muat
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: colorScheme.surface,
              elevation: 1,
              shadowColor: Colors.black12,
              iconTheme: IconThemeData(color: colorScheme.onSurface),
              actions: [
                // TOMBOL SIMPAN MANUAL (Mode Bangunan)
                if (widget.buildingDirectory != null && !isView)
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.blue),
                    tooltip: "Simpan Denah",
                    onPressed: _saveBuildingPlan,
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
                          leading: Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
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
                Positioned.fill(child: PlanCanvasView(controller: _controller)),

                if (!isView && _controller.selectedId != null)
                  Positioned(
                    bottom: 140,
                    left: 16,
                    right: 16,
                    child: PlanSelectionBar(controller: _controller),
                  ),

                if (!isView)
                  Positioned(
                    bottom: 32,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: PlanEditorToolbar(controller: _controller),
                    ),
                  ),

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
          ),
        );
      },
    );
  }
}
