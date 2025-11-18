// lib/features/building/presentation/management/building_management_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/management/district_building_management_page.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_editor_page.dart';
import 'package:mind_palace_manager/permission_helper.dart';

class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  List<Directory> _districtFolders = [];
  bool _isLoading = false;
  final TextEditingController _newDistrictController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDistricts());
  }

  @override
  void dispose() {
    _newDistrictController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() {
      _isLoading = true;
    });

    bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin penyimpanan ditolak. Tidak dapat memuat distrik.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

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
      final rootDir = Directory(AppSettings.baseBuildingsPath!);
      if (!await rootDir.exists()) {
        await rootDir.create(recursive: true);
      }

      final entities = await rootDir.list().toList();
      setState(() {
        _districtFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat distrik: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreateDistrictDialog() async {
    _newDistrictController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Distrik Baru'),
          content: TextField(
            controller: _newDistrictController,
            decoration: const InputDecoration(hintText: 'Nama Distrik'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Buat'),
              onPressed: _createNewDistrict,
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewDistrict() async {
    if (AppSettings.baseBuildingsPath == null) {
      Navigator.of(context).pop();
      _loadDistricts();
      return;
    }

    final String districtName = _newDistrictController.text.trim();
    if (districtName.isEmpty) return;

    try {
      final newDistrictPath = p.join(
        AppSettings.baseBuildingsPath!,
        districtName,
      );
      final newDir = Directory(newDistrictPath);
      await newDir.create(recursive: true);

      final dataJsonFile = File(p.join(newDistrictPath, 'district_data.json'));
      await dataJsonFile.writeAsString(
        json.encode({"map_image": null, "building_placements": []}),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
      await _loadDistricts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Distrik "$districtName" berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat distrik: $e')));
      }
    }
  }

  void _viewDistrict(Directory districtDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DistrictBuildingManagementPage(districtDirectory: districtDir),
      ),
    );
  }

  void _editDistrictMap(Directory districtDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DistrictMapEditorPage(districtDirectory: districtDir),
      ),
    );
  }

  Future<void> _deleteDistrict(Directory districtDir) async {
    final districtName = p.basename(districtDir.path);

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Distrik'),
          content: Text(
            'Apakah Anda yakin ingin menghapus distrik "$districtName"?\n\n'
            'PERINGATAN: Tindakan ini akan menghapus SEMUA bangunan di dalamnya secara permanen.',
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
        await districtDir.delete(recursive: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Distrik "$districtName" berhasil dihapus.'),
            ),
          );
        }
        await _loadDistricts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus distrik: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Distrik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDistricts,
            tooltip: 'Muat Ulang Daftar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDistrictDialog,
        tooltip: 'Buat Distrik Baru',
        child: const Icon(Icons.add_location_alt),
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

    if (_districtFolders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada distrik.\nKlik tombol + untuk membuat yang baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _districtFolders.length,
      itemBuilder: (context, index) {
        final folder = _districtFolders[index];
        final folderName = p.basename(folder.path);
        return ListTile(
          leading: const Icon(Icons.holiday_village, size: 40),
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          // --- PERUBAHAN: Mengganti Row dengan PopupMenuButton ---
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opsi Distrik',
            onSelected: (String value) {
              switch (value) {
                case 'view':
                  _viewDistrict(folder);
                  break;
                case 'edit_map':
                  _editDistrictMap(folder);
                  break;
                case 'delete':
                  _deleteDistrict(folder);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Lihat'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit_map',
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit Peta'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          // --- SELESAI PERUBAHAN ---
          onTap: () => _viewDistrict(folder),
        );
      },
    );
  }
}
