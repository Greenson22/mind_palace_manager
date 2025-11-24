import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/management/logic/district_building_logic.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/plan_editor_page.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/plan_painter.dart';

class BuildingPlanListPage extends StatefulWidget {
  final Directory buildingDirectory;
  final String buildingName;

  const BuildingPlanListPage({
    super.key,
    required this.buildingDirectory,
    required this.buildingName,
  });

  @override
  State<BuildingPlanListPage> createState() => _BuildingPlanListPageState();
}

class _BuildingPlanListPageState extends State<BuildingPlanListPage> {
  late DistrictBuildingLogic _logic;
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Logic inisialisasi dengan direktori distrik (parent dari bangunan)
    _logic = DistrictBuildingLogic(widget.buildingDirectory.parent);
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final plans = await _logic.getBuildingPlans(widget.buildingDirectory);
    setState(() {
      _plans = plans;
      _isLoading = false;
    });
  }

  Future<void> _addPlan() async {
    final nameCtrl = TextEditingController();
    IconData selectedIcon = Icons.layers;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Tambah Denah/Lantai"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama (mis: Lantai 2)",
                  ),
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
                    await _logic.addPlanToBuilding(
                      widget.buildingDirectory,
                      nameCtrl.text.trim(),
                      selectedIcon.codePoint,
                    );
                    if (mounted) Navigator.pop(c);
                    _loadPlans();
                  }
                },
                child: const Text("Buat"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPlanEditor(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          buildingDirectory: widget.buildingDirectory,
          planFilename: plan['filename'],
          planName: plan['name'],
        ),
      ),
    ).then((_) => _loadPlans());
  }

  Future<void> _editPlanInfo(Map<String, dynamic> plan) async {
    final nameCtrl = TextEditingController(text: plan['name']);
    int currentIconCode = plan['icon'] ?? Icons.map.codePoint;
    IconData selectedIcon = IconData(
      currentIconCode,
      fontFamily: 'MaterialIcons',
    );

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Info Denah"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nama"),
                ),
                const SizedBox(height: 16),
                const Text("Pilih Ikon:"),
                Wrap(
                  spacing: 8,
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
                    await _logic.updatePlanInfo(
                      widget.buildingDirectory,
                      plan['id'],
                      nameCtrl.text.trim(),
                      selectedIcon.codePoint,
                    );
                    if (mounted) Navigator.pop(c);
                    _loadPlans();
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

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hapus Denah?"),
        content: Text("Denah '${plan['name']}' akan dihapus permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logic.deletePlan(
        widget.buildingDirectory,
        plan['id'],
        plan['filename'],
      );
      _loadPlans();
    }
  }

  // --- EXPORT GAMBAR ---
  Future<void> _exportPlanImage(Map<String, dynamic> plan) async {
    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Atur folder export di Pengaturan dulu.")),
      );
      return;
    }

    final planFile = File(
      p.join(widget.buildingDirectory.path, plan['filename']),
    );
    if (!await planFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File denah tidak ditemukan.")),
      );
      return;
    }

    try {
      // Load Controller secara headless
      final controller = PlanController();
      await controller.loadFromPath(planFile.path);

      final recorder = ui.PictureRecorder();
      final exportSize = Size(controller.canvasWidth, controller.canvasHeight);
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
      );

      // Gambar Background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
        Paint()..color = controller.canvasColor,
      );

      // Gambar Konten
      final painter = PlanPainter(controller: controller);
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
            'plan_${plan['name'].replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}.png';
        final file = File(p.join(AppSettings.exportPath!, fileName));
        await file.writeAsBytes(pngBytes.buffer.asUint8List());
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil diexport: ${file.path}"),
              backgroundColor: Colors.green,
            ),
          );
      }
      controller.dispose();
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

  // --- PINDAH KE BANGUNAN LAIN ---
  Future<void> _movePlanToAnotherBuilding(Map<String, dynamic> plan) async {
    final districtDir = widget.buildingDirectory.parent;
    List<Directory> buildings = [];
    try {
      buildings = districtDir
          .listSync()
          .whereType<Directory>()
          .where(
            (d) => d.path != widget.buildingDirectory.path,
          ) // Exclude current
          .toList();
    } catch (_) {}

    if (buildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ada bangunan lain di distrik ini."),
        ),
      );
      return;
    }

    Directory? targetBuilding;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Pindahkan Denah ke..."),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: buildings.length,
            itemBuilder: (ctx, i) {
              return ListTile(
                leading: const Icon(Icons.business),
                title: Text(p.basename(buildings[i].path)),
                onTap: () {
                  targetBuilding = buildings[i];
                  Navigator.pop(c);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Batal"),
          ),
        ],
      ),
    );

    if (targetBuilding != null) {
      try {
        // 1. Pindahkan File
        final oldFile = File(
          p.join(widget.buildingDirectory.path, plan['filename']),
        );
        final newFilename =
            "moved_${DateTime.now().millisecondsSinceEpoch}_${plan['filename']}";
        final newFile = File(p.join(targetBuilding!.path, newFilename));

        await oldFile.copy(newFile.path);
        await oldFile.delete();

        // 2. Update Data JSON di Bangunan Lama (Hapus)
        await _logic.deletePlan(
          widget.buildingDirectory,
          plan['id'],
          plan['filename'],
        ); // Hapus entry & file (file sdh dihapus di atas, tp safe)

        // 3. Update Data JSON di Bangunan Baru (Tambah)
        // Kita perlu instance logic baru atau fungsi helper, tapi kita bisa manual add entry
        final targetJsonFile = File(p.join(targetBuilding!.path, 'data.json'));
        if (await targetJsonFile.exists()) {
          final content = await targetJsonFile.readAsString();
          final data = json.decode(content);
          List<dynamic> plans = data['plans'] ?? [];
          plans.add({
            'id': plan['id'], // Keep ID
            'name': plan['name'],
            'filename': newFilename,
            'icon': plan['icon'],
          });
          data['plans'] = plans;
          await targetJsonFile.writeAsString(json.encode(data));
        }

        _loadPlans();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Denah dipindahkan ke ${p.basename(targetBuilding!.path)}",
              ),
              backgroundColor: Colors.green,
            ),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal memindahkan: $e"),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Denah: ${widget.buildingName}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum ada denah.\nTekan + untuk membuat lantai/denah baru.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              buildDefaultDragHandles: true, // Aktifkan long-press drag
              itemCount: _plans.length,
              onReorder: (oldIdx, newIdx) async {
                await _logic.reorderPlans(
                  widget.buildingDirectory,
                  oldIdx,
                  newIdx,
                );
                _loadPlans();
              },
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return Card(
                  key: ValueKey(plan['id']),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      IconData(
                        plan['icon'] ?? Icons.map.codePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                      color: Colors.indigo,
                      size: 28,
                    ),
                    title: Text(
                      plan['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: index == 0
                        ? const Text(
                            "Default (Dibuka Pertama)",
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          )
                        : null,
                    // --- BAGIAN MENU BARU ---
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editPlanInfo(plan);
                        if (value == 'export') _exportPlanImage(plan);
                        if (value == 'move') _movePlanToAnotherBuilding(plan);
                        if (value == 'delete') _deletePlan(plan);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.orange),
                            title: Text("Edit Info"),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: ListTile(
                            leading: Icon(Icons.image, color: Colors.blue),
                            title: Text("Export Gambar"),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'move',
                          child: ListTile(
                            leading: Icon(
                              Icons.drive_file_move,
                              color: Colors.teal,
                            ),
                            title: Text("Pindahkan"),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text("Hapus"),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _openPlanEditor(plan),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
