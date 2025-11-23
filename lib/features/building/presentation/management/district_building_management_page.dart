import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/permission_helper.dart';
import 'package:mind_palace_manager/features/settings/helpers/cloud_transition.dart';

// --- Pages & Dialogs ---
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_viewer_page.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_editor_page.dart';
import 'package:mind_palace_manager/features/building/presentation/dialogs/move_building_dialog.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/plan_editor_page.dart';
// --- IMPORT HALAMAN BARU ---
import 'package:mind_palace_manager/features/building/presentation/management/building_plan_list_page.dart';

// --- Refactored Modules ---
import 'logic/district_building_logic.dart';
import 'dialogs/building_management_dialogs.dart';
import 'widgets/building_list_item.dart';

class DistrictBuildingManagementPage extends StatefulWidget {
  final Directory districtDirectory;
  const DistrictBuildingManagementPage({
    super.key,
    required this.districtDirectory,
  });

  @override
  State<DistrictBuildingManagementPage> createState() =>
      _DistrictBuildingManagementPageState();
}

class _DistrictBuildingManagementPageState
    extends State<DistrictBuildingManagementPage> {
  late DistrictBuildingLogic _logic;
  List<Directory> _buildingFolders = [];
  bool _isLoading = false;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    _logic = DistrictBuildingLogic(widget.districtDirectory);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshList());
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    if (!await checkAndRequestPermissions()) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin ditolak')));
      setState(() => _isLoading = false);
      return;
    }
    try {
      final list = await _logic.loadBuildings();
      setState(() => _buildingFolders = list);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleCreate() async {
    final result = await BuildingManagementDialogs.showCreateDialog(context);
    if (result != null) {
      await _logic.createBuilding(
        result['name'],
        result['type'],
        result['iconType'],
        result['iconData'],
        sourceImagePath: result['imagePath'],
      );
      _refreshList();
    }
  }

  Future<void> _handleEdit(Directory folder) async {
    final iconData = await _logic.getBuildingIconData(folder);
    if (!mounted) return;
    final result = await BuildingManagementDialogs.showEditDialog(
      context,
      p.basename(folder.path),
      iconData['type'] ?? 'Default',
      iconData['data'],
    );
    if (result != null) {
      await _logic.updateBuilding(
        folder,
        result['name'],
        result['iconType'],
        result['iconData'],
        newImagePath: result['imagePath'],
      );
      _refreshList();
    }
  }

  Future<void> _handleDelete(Directory folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Bangunan?'),
        content: const Text('Tindakan ini permanen.'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(c, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _logic.deleteBuilding(folder);
      await _logic.removeBuildingFromMapData(p.basename(folder.path));
      _refreshList();
    }
  }

  Future<void> _handleMove(Directory folder) async {
    final Directory? targetDistrict = await showDialog<Directory>(
      context: context,
      builder: (context) => MoveBuildingDialog(
        currentRegionDir: widget.districtDirectory.parent,
        currentDistrictDir: widget.districtDirectory,
      ),
    );

    if (targetDistrict != null) {
      setState(() => _isLoading = true);
      try {
        final name = p.basename(folder.path);
        String newName = name;
        if (await Directory(p.join(targetDistrict.path, name)).exists()) {
          newName = "${name}_${DateTime.now().millisecondsSinceEpoch}";
        }
        await folder.rename(p.join(targetDistrict.path, newName));
        await _logic.removeBuildingFromMapData(name);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Dipindahkan ke ${p.basename(targetDistrict.path)}',
              ),
            ),
          );
        _refreshList();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal pindah: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRetract(Directory folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Simpan ke Bank?'),
        content: const Text(
          'Pindahkan ke gudang. Data peta distrik akan dihapus.',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(c, false),
          ),
          ElevatedButton(
            child: const Text('Simpan'),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _logic.retractToWarehouse(folder);
        _refreshList();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tersimpan di Bank.')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleExportIcon(Directory folder) async {
    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atur folder export di Pengaturan.')),
      );
      return;
    }
    final iconData = await _logic.getBuildingIconData(folder);
    if (iconData['type'] == 'image' && iconData['file'] != null) {
      final File f = iconData['file'];
      final dest = p.join(
        AppSettings.exportPath!,
        'icon_${p.basename(folder.path)}_${DateTime.now().millisecondsSinceEpoch}${p.extension(f.path)}',
      );
      await f.copy(dest);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ikon diexport.')));
    } else {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bukan ikon gambar.')));
    }
  }

  // --- Navigasi Utama (MODIFIED) ---
  Future<void> _navigateToView(
    Directory folder, {
    bool editMode = false,
  }) async {
    String type = 'standard';
    try {
      final file = File(p.join(folder.path, 'data.json'));
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        type = data['type'] ?? 'standard';
      }
    } catch (_) {}

    if (!mounted) return;

    if (type == 'plan') {
      // --- LOGIKA BARU UNTUK DENAH ---
      // Cek daftar denah di logic
      final plans = await _logic.getBuildingPlans(folder);

      if (plans.isEmpty) {
        // Jika kosong, buka halaman manajemen agar user buat baru
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => BuildingPlanListPage(
              buildingDirectory: folder,
              buildingName: p.basename(folder.path),
            ),
          ),
        );
      } else {
        // Buka denah PERTAMA (Index 0) secara default
        final firstPlan = plans[0];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanEditorPage(
              buildingDirectory: folder,
              initialViewMode: !editMode,
              // Kirim nama file denah spesifik
              planFilename: firstPlan['filename'],
              planName: firstPlan['name'],
            ),
          ),
        );
      }
    } else {
      // Bangunan Biasa (Room Viewer)
      CloudNavigation.push(
        context,
        BuildingViewerPage(buildingDirectory: folder),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Distrik: ${p.basename(widget.districtDirectory.path)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Peta Distrik',
            onPressed: () => CloudNavigation.push(
              context,
              DistrictMapViewerPage(
                districtDirectory: widget.districtDirectory,
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshList),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildingFolders.isEmpty
          ? const Center(
              child: Text(
                'Belum ada bangunan.\nTekan + untuk membuat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _buildingFolders.length,
              itemBuilder: (context, index) {
                final folder = _buildingFolders[index];
                return BuildingListItem(
                  buildingFolder: folder,
                  iconDataFuture: _logic.getBuildingIconData(folder),
                  // Tap utama selalu ke mode view (Denah pertama atau Room Viewer)
                  onTap: () => _navigateToView(folder),
                  onActionSelected: (action) {
                    if (action == 'view') _navigateToView(folder);
                    // Aksi khusus Edit Plan (Buka denah pertama dalam mode edit)
                    if (action == 'edit_plan') {
                      _navigateToView(folder, editMode: true);
                    }
                    // --- MENU BARU: KELOLA DENAH ---
                    if (action == 'manage_plans') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => BuildingPlanListPage(
                            buildingDirectory: folder,
                            buildingName: p.basename(folder.path),
                          ),
                        ),
                      );
                    }
                    // Aksi khusus Edit Ruangan (Bangunan Biasa)
                    if (action == 'edit_room') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              RoomEditorPage(buildingDirectory: folder),
                        ),
                      );
                    }
                    if (action == 'edit_info') _handleEdit(folder);
                    if (action == 'move') _handleMove(folder);
                    if (action == 'retract') _handleRetract(folder);
                    if (action == 'export_icon') _handleExportIcon(folder);
                    if (action == 'delete') _handleDelete(folder);
                  },
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabOpen) ...[
            _buildFabItem(
              icon: Icons.map,
              label: "Edit Peta",
              color: Colors.blue.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => DistrictMapEditorPage(
                      districtDirectory: widget.districtDirectory,
                    ),
                  ),
                );
                setState(() => _isFabOpen = false);
              },
            ),
            const SizedBox(height: 16),
            _buildFabItem(
              icon: Icons.add_business,
              label: "Buat Bangunan",
              onTap: () {
                _handleCreate();
                setState(() => _isFabOpen = false);
              },
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: 'toggle',
            onPressed: () => setState(() => _isFabOpen = !_isFabOpen),
            child: Icon(_isFabOpen ? Icons.close : Icons.apps),
          ),
        ],
      ),
    );
  }

  Widget _buildFabItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, color: Colors.black87),
        ),
      ],
    );
  }
}
