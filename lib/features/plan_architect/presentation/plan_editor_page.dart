import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mind_palace_manager/features/building/presentation/management/logic/district_building_logic.dart';
import 'package:mind_palace_manager/features/building/presentation/management/building_plan_list_page.dart';

class PlanEditorPage extends StatefulWidget {
  // Parameter opsional: jika diisi, editor berjalan dalam mode "Bangunan Denah"
  final Directory? buildingDirectory;

  // Opsi untuk membuka langsung dalam mode lihat
  final bool initialViewMode;

  // --- Parameter untuk Multi-Denah ---
  final String? planFilename; // Nama file spesifik (misal: plan_123.json)
  final String? planName; // Nama tampilan (misal: Lantai 1)

  const PlanEditorPage({
    super.key,
    this.buildingDirectory,
    this.initialViewMode = false,
    this.planFilename,
    this.planName,
  });

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  final PlanController _controller = PlanController();

  // Local state untuk nama & file saat ini (agar bisa berubah saat navigasi)
  late String _currentFilename;
  String? _currentPlanName;

  @override
  void initState() {
    super.initState();
    _currentFilename = widget.planFilename ?? 'plan.json';
    _currentPlanName = widget.planName;

    // --- UPDATE: Set Directory ke Controller agar bisa resolve path ---
    _controller.buildingDirectory = widget.buildingDirectory;
    // -----------------------------------------------------------------

    // Jika dibuka dari bangunan, muat file plan yang sesuai
    if (widget.buildingDirectory != null) {
      _loadBuildingPlan(_currentFilename);
    }

    // Set mode awal
    if (widget.initialViewMode) {
      _controller.isViewMode = true;
      _controller.activeTool = PlanTool.select;
    }
  }

  Future<void> _loadBuildingPlan(String filename) async {
    final planFile = p.join(widget.buildingDirectory!.path, filename);
    await _controller.loadFromPath(planFile);
  }

  Future<void> _saveBuildingPlan() async {
    // Cek apakah ada perubahan sebelum menyimpan
    if (!_controller.hasUnsavedChanges) return;

    if (widget.buildingDirectory != null) {
      final planFile = p.join(widget.buildingDirectory!.path, _currentFilename);
      await _controller.saveToPath(planFile);

      // Notifikasi Save hanya muncul jika benar-benar ada yang disimpan
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

  // --- IMPLEMENTASI NAVIGASI ---
  Future<void> _handleNavigation(String targetPlanId) async {
    if (widget.buildingDirectory == null) return;

    // 1. Ambil daftar plan untuk mencari filename dari ID
    final logic = DistrictBuildingLogic(widget.buildingDirectory!.parent);
    final plans = await logic.getBuildingPlans(widget.buildingDirectory!);

    try {
      final targetPlan = plans.firstWhere((p) => p['id'] == targetPlanId);

      // 2. Simpan perubahan secara otomatis (jika ada edit) sebelum pindah
      await _saveBuildingPlan();

      // 3. Load plan baru
      setState(() {
        _currentFilename = targetPlan['filename'];
        _currentPlanName = targetPlan['name'];
      });

      await _loadBuildingPlan(_currentFilename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Denah tujuan tidak ditemukan.")),
        );
      }
    }
  }

  // --- BARU: KELOLA DAFTAR DENAH ---
  void _openPlanList() {
    if (widget.buildingDirectory == null) return;

    // Simpan dulu sebelum pindah
    _saveBuildingPlan();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => BuildingPlanListPage(
          buildingDirectory: widget.buildingDirectory!,
          buildingName: p.basename(widget.buildingDirectory!.path),
        ),
      ),
    ).then((_) {
      // Saat kembali, reload info siapa tahu nama/urutan berubah
      // Untuk amannya kita tetap di file yang sama, tapi update namanya jika berubah
      _refreshCurrentPlanInfo();
    });
  }

  Future<void> _refreshCurrentPlanInfo() async {
    if (widget.buildingDirectory == null) return;
    final logic = DistrictBuildingLogic(widget.buildingDirectory!.parent);
    final plans = await logic.getBuildingPlans(widget.buildingDirectory!);

    try {
      // Cari plan yang sedang dibuka berdasarkan filename
      final currentPlan = plans.firstWhere(
        (p) => p['filename'] == _currentFilename,
      );
      setState(() {
        _currentPlanName = currentPlan['name'];
      });
    } catch (_) {
      // Jika file yang sedang dibuka dihapus dari list, mungkin perlu exit atau warning
    }
  }

  // --- BARU: UBAH INFO DENAH (NAMA/IKON) ---
  Future<void> _editCurrentPlanInfo() async {
    if (widget.buildingDirectory == null) return;

    final logic = DistrictBuildingLogic(widget.buildingDirectory!.parent);
    final plans = await logic.getBuildingPlans(widget.buildingDirectory!);

    Map<String, dynamic>? currentPlan;
    try {
      currentPlan = plans.firstWhere((p) => p['filename'] == _currentFilename);
    } catch (_) {
      return;
    }

    final nameCtrl = TextEditingController(text: currentPlan['name']);
    int currentIconCode = currentPlan['icon'] ?? Icons.map.codePoint;
    IconData selectedIcon = IconData(
      currentIconCode,
      fontFamily: 'MaterialIcons',
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Info Denah Ini"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nama"),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Pilih Ikon:", style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children:
                      [
                        Icons.layers,
                        Icons.stairs,
                        Icons.roofing,
                        Icons.warehouse,
                        Icons.bed,
                        Icons.kitchen,
                        Icons.deck,
                        Icons.map,
                        Icons.grid_view,
                      ].map((icon) {
                        return IconButton(
                          icon: Icon(icon),
                          color: selectedIcon == icon
                              ? Colors.blue
                              : Colors.grey,
                          onPressed: () =>
                              setStateDialog(() => selectedIcon = icon),
                        );
                      }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    await logic.updatePlanInfo(
                      widget.buildingDirectory!,
                      currentPlan!['id'],
                      nameCtrl.text.trim(),
                      selectedIcon.codePoint,
                    );
                    setState(() {
                      _currentPlanName = nameCtrl.text.trim();
                    });
                    if (mounted) Navigator.pop(c);
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
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
        String prefix = "plan";
        if (widget.buildingDirectory != null) {
          prefix = "plan_${p.basename(widget.buildingDirectory!.path)}";
          if (_currentPlanName != null) {
            prefix += "_${_currentPlanName!.replaceAll(' ', '_')}";
          }
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
        if (_currentPlanName != null) {
          title += " - $_currentPlanName";
        } else if (widget.buildingDirectory != null) {
          title += " (${p.basename(widget.buildingDirectory!.path)})";
        }

        return PopScope(
          canPop: false,
          onPopInvoked: _onWillPop,
          child: Scaffold(
            // --- TRANSPARENT APPBAR SETTINGS ---
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              actions: [
                if (widget.buildingDirectory != null && !isView)
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.lightBlueAccent),
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
                    if (v == 'manage_plans') {
                      _openPlanList();
                    } else if (v == 'edit_info') {
                      _editCurrentPlanInfo();
                    } else if (v == 'settings') {
                      PlanEditorDialogs.showLayerSettings(context, _controller);
                    } else if (v == 'export') {
                      _exportImage();
                    } else if (v == 'clear') {
                      _controller.clearAll();
                    }
                  },
                  itemBuilder: (ctx) => [
                    // --- MENU TAMBAHAN PENTING ---
                    if (widget.buildingDirectory != null) ...[
                      const PopupMenuItem(
                        value: 'manage_plans',
                        child: ListTile(
                          leading: Icon(Icons.layers, color: Colors.purple),
                          title: Text('Kelola Daftar Denah'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit_info',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.orange),
                          title: Text('Ubah Info Denah Ini'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuDivider(),
                    ],
                    // -----------------------------
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings_display),
                        title: Text('Tampilan & Ukuran'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    // Export selalu tampil (baik View maupun Edit mode)
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.save_alt),
                        title: Text('Export Gambar'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    // Hapus semua hanya di Edit Mode
                    if (!isView) ...[
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
                Positioned.fill(
                  child: PlanCanvasView(
                    controller: _controller,
                    onNavigate: _handleNavigation,
                  ),
                ),

                if (!isView && _controller.selectedId != null)
                  Positioned(
                    bottom: 140,
                    left: 16,
                    right: 16,
                    child: PlanSelectionBar(
                      controller: _controller,
                      buildingDirectory: widget.buildingDirectory,
                      currentPlanFilename: _currentFilename,
                    ),
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
                    top: 100, // Turunkan karena AppBar transparan
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
                    top: 100, // Turunkan karena AppBar transparan
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
