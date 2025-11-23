import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mind_palace_manager/features/building/presentation/management/logic/district_building_logic.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/plan_editor_page.dart';

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
              buildDefaultDragHandles: false,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          tooltip: "Edit Info",
                          onPressed: () => _editPlanInfo(plan),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Hapus",
                          onPressed: () => _deletePlan(plan),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0, right: 8.0),
                            child: Icon(Icons.drag_handle, color: Colors.grey),
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
