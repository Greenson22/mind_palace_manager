// lib/features/building/presentation/management/building_management_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';

// --- TAMBAHAN ---
// Impor helper izin
import 'package:mind_palace_manager/permission_helper.dart';
// --- SELESAI TAMBAHAN ---

class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  List<Directory> _buildingFolders = [];
  bool _isLoading = false;
  final TextEditingController _newBuildingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuildings());
  }

  @override
  void dispose() {
    _newBuildingController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoading = true;
    });

    // --- TAMBAHAN: Pengecekan Izin ---
    // Tambahkan pengecekan di sini sebagai pengaman jika pengguna
    // mencabut izin saat aplikasi berjalan.
    bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin penyimpanan ditolak. Tidak dapat memuat bangunan.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }
    // --- SELESAI TAMBAHAN ---

    if (AppSettings.baseBuildingsPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Path utama belum diatur. Silakan ke Pengaturan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final buildingsDir = Directory(AppSettings.baseBuildingsPath!);
      if (!await buildingsDir.exists()) {
        await buildingsDir.create(recursive: true);
      }

      final entities = await buildingsDir.list().toList();
      setState(() {
        _buildingFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat bangunan: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreateBuildingDialog() async {
    _newBuildingController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Bangunan Baru'),
          content: TextField(
            controller: _newBuildingController,
            decoration: const InputDecoration(hintText: 'Nama Bangunan'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Buat'),
              onPressed: _createNewBuilding,
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewBuilding() async {
    if (AppSettings.baseBuildingsPath == null) {
      Navigator.of(context).pop();
      _loadBuildings();
      return;
    }

    final String buildingName = _newBuildingController.text.trim();
    if (buildingName.isEmpty) return;

    try {
      final newBuildingPath = p.join(
        AppSettings.baseBuildingsPath!,
        buildingName,
      );
      final newDir = Directory(newBuildingPath);
      await newDir.create(recursive: true);

      final dataJsonFile = File(p.join(newBuildingPath, 'data.json'));
      await dataJsonFile.writeAsString(json.encode({"rooms": []}));

      if (mounted) {
        Navigator.of(context).pop();
      }
      await _loadBuildings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bangunan "$buildingName" berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat bangunan: $e')));
      }
    }
  }

  void _viewBuilding(Directory buildingDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Arahkan ke Viewer
        builder: (context) =>
            BuildingViewerPage(buildingDirectory: buildingDir),
      ),
    );
  }

  void _editBuilding(Directory buildingDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Arahkan ke Editor
        builder: (context) => RoomEditorPage(buildingDirectory: buildingDir),
      ),
    );
  }

  Future<void> _deleteBuilding(Directory buildingDir) async {
    final buildingName = p.basename(buildingDir.path);

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Bangunan'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$buildingName"?\n\n'
            'Tindakan ini akan menghapus semua folder, ruangan, dan gambar di dalamnya secara permanen.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      try {
        await buildingDir.delete(recursive: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bangunan "$buildingName" berhasil dihapus.'),
            ),
          );
        }
        await _loadBuildings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus bangunan: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Bangunan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuildings,
            tooltip: 'Muat Ulang Daftar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBuildingDialog,
        tooltip: 'Buat Bangunan Baru',
        child: const Icon(Icons.add_business),
      ),
    );
  }

  Widget _buildBody() {
    if (AppSettings.baseBuildingsPath == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Lokasi folder utama belum diatur.\nSilakan pergi ke "Pengaturan" terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buildingFolders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada bangunan.\nKlik tombol + untuk membuat yang baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _buildingFolders.length,
      itemBuilder: (context, index) {
        final folder = _buildingFolders[index];
        final folderName = p.basename(folder.path);
        return ListTile(
          leading: const Icon(Icons.location_city, size: 40),
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: 'Lihat',
                onPressed: () => _viewBuilding(folder),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Ruangan',
                onPressed: () => _editBuilding(folder),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Hapus',
                onPressed: () => _deleteBuilding(folder),
              ),
            ],
          ),
          onTap: null,
        );
      },
    );
  }
}
