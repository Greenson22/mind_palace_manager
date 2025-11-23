import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/helpers/cloud_transition.dart';

// Pages
import 'package:mind_palace_manager/features/world/presentation/map/world_map_editor_page.dart';
import 'package:mind_palace_manager/features/world/presentation/map/world_map_viewer_page.dart';
import 'package:mind_palace_manager/features/region/presentation/management/region_detail_page.dart';
import 'package:mind_palace_manager/features/building/presentation/factory/building_factory_page.dart';

// New Components
import 'logic/world_region_logic.dart';
import 'dialogs/region_dialogs.dart';
import 'widgets/region_list_item.dart';
import 'widgets/world_fab_menu.dart';

class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  final WorldRegionLogic _logic = WorldRegionLogic();
  List<Directory> _regions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshList());
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    try {
      final list = await _logic.loadRegions();
      setState(() => _regions = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat wilayah: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  // --- Actions ---

  Future<void> _handleCreate() async {
    final name = await RegionDialogs.showCreateDialog(context);
    if (name != null) {
      try {
        await _logic.createRegion(name);
        _refreshList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Wilayah "$name" berhasil dibuat')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _handleEdit(Directory regionDir) async {
    final iconData = await _logic.getRegionIconData(regionDir);
    final mapImage = await _logic.getRegionMapImageName(regionDir);

    if (!mounted) return;

    final result = await RegionDialogs.showEditDialog(
      context,
      regionDir.path.split(Platform.pathSeparator).last, // Nama Folder
      iconData['type'] ?? 'Default',
      iconData['data'],
      mapImage,
    );

    if (result != null) {
      await _logic.updateRegion(
        regionDir,
        result['name'],
        result['iconType'],
        result['iconData'],
        newImagePath: result['imagePath'],
      );
      _refreshList();
    }
  }

  Future<void> _handleDelete(Directory regionDir) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Wilayah?'),
        content: const Text(
          'Semua distrik & bangunan di dalamnya akan hilang permanen.',
        ),
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
      await _logic.deleteRegion(regionDir);
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dunia Ingatan (Wilayah)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Lihat Peta Dunia',
            onPressed: () {
              if (AppSettings.baseBuildingsPath != null) {
                CloudNavigation.push(
                  context,
                  WorldMapViewerPage(
                    worldDirectory: Directory(AppSettings.baseBuildingsPath!),
                  ),
                );
              }
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshList),
          IconButton(
            icon: const Icon(Icons.warehouse),
            tooltip: 'Bank Bangunan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const BuildingFactoryPage()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: WorldFabMenu(
        onCreateRegion: _handleCreate,
        onEditMap: () {
          if (AppSettings.baseBuildingsPath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => WorldMapEditorPage(
                  worldDirectory: Directory(AppSettings.baseBuildingsPath!),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (AppSettings.baseBuildingsPath == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Lokasi folder utama belum diatur.\nSilakan pergi ke "Pengaturan".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_regions.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada wilayah.\nKlik tombol menu di kanan bawah.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _regions.length,
      itemBuilder: (context, index) {
        final dir = _regions[index];
        return RegionListItem(
          regionDir: dir,
          iconDataFuture: _logic.getRegionIconData(dir),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => RegionDetailPage(regionDirectory: dir),
              ),
            );
          },
          onAction: (action) {
            if (action == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => RegionDetailPage(regionDirectory: dir),
                ),
              );
            } else if (action == 'edit') {
              _handleEdit(dir);
            } else if (action == 'delete') {
              _handleDelete(dir);
            }
          },
        );
      },
    );
  }
}
