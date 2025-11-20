import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
import 'package:mind_palace_manager/features/building/presentation/dialogs/move_building_dialog.dart';

class BuildingFactoryPage extends StatefulWidget {
  const BuildingFactoryPage({super.key});

  @override
  State<BuildingFactoryPage> createState() => _BuildingFactoryPageState();
}

class _BuildingFactoryPageState extends State<BuildingFactoryPage> {
  Directory? _warehouseDir;
  List<Directory> _bankBuildings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initWarehouse();
  }

  Future<void> _initWarehouse() async {
    if (AppSettings.baseBuildingsPath == null) return;

    // Nama folder khusus untuk Gudang/Bank (Tersembunyi dari peta dunia)
    final rootPath = AppSettings.baseBuildingsPath!;
    _warehouseDir = Directory(p.join(rootPath, '_BUILDING_WAREHOUSE_'));

    if (!await _warehouseDir!.exists()) {
      await _warehouseDir!.create();
    }
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    if (_warehouseDir == null) return;
    setState(() => _isLoading = true);

    try {
      final entities = await _warehouseDir!.list().toList();
      _bankBuildings = entities.whereType<Directory>().toList();
    } catch (e) {
      debugPrint("Error loading warehouse: $e");
    }

    setState(() => _isLoading = false);
  }

  // --- CRUD DASAR (Sama seperti manajemen distrik) ---

  Future<void> _createNewBuilding() async {
    final controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Buat Template Bangunan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Bangunan'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Buat'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      try {
        final newDir = Directory(p.join(_warehouseDir!.path, name));
        await newDir.create();
        // Buat data.json kosong
        await File(
          p.join(newDir.path, 'data.json'),
        ).writeAsString(json.encode({"rooms": []}));
        _loadBuildings();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _editBuilding(Directory dir) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => RoomEditorPage(buildingDirectory: dir)),
    );
  }

  Future<void> _deleteBuilding(Directory dir) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus dari Bank?'),
        content: const Text('Bangunan ini akan hilang permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
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
      await dir.delete(recursive: true);
      _loadBuildings();
    }
  }

  // --- FITUR UTAMA: DEPLOY (Menyebar ke Distrik) ---

  Future<void> _deployBuilding(Directory buildingDir) async {
    if (AppSettings.baseBuildingsPath == null) return;

    // 1. Pilih Tujuan (Menggunakan Dialog Move yang sudah ada)
    // Kita kirim _warehouseDir sebagai "region" semu agar navigasi berjalan
    final Directory? targetDistrict = await showDialog<Directory>(
      context: context,
      builder: (context) => MoveBuildingDialog(
        currentRegionDir: _warehouseDir!,
        currentDistrictDir:
            _warehouseDir!, // Dummy, agar tidak memfilter apapun
      ),
    );

    if (targetDistrict == null) return;

    // 2. Pilih Metode: PINDAH atau SALIN
    final String? mode = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pilih Metode Penempatan'),
        content: Text(
          'Ingin memindahkan bangunan ini sepenuhnya atau hanya menyalinnya?\n\nTujuan: ${p.basename(targetDistrict.path)}',
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Salin (Copy)'),
            onPressed: () => Navigator.pop(c, 'copy'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.forward),
            label: const Text('Pindahkan'),
            onPressed: () => Navigator.pop(c, 'move'),
          ),
        ],
      ),
    );

    if (mode == null) return;

    setState(() => _isLoading = true);

    try {
      final String name = p.basename(buildingDir.path);
      String newName = name;

      // Cek duplikasi nama di tujuan
      final destPath = p.join(targetDistrict.path, name);
      if (await Directory(destPath).exists()) {
        newName = "${name}_${DateTime.now().millisecondsSinceEpoch}";
      }
      final finalDestPath = p.join(targetDistrict.path, newName);

      if (mode == 'move') {
        // MODE PINDAH (Rename)
        await buildingDir.rename(finalDestPath);
      } else {
        // MODE SALIN (Recursive Copy)
        await _copyDirectory(buildingDir, Directory(finalDestPath));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bangunan berhasil di-${mode == 'move' ? 'pindahkan' : 'salin'} ke $newName',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadBuildings(); // Refresh list (jika dipindahkan, akan hilang)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal deploy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Helper: Copy Directory secara rekursif
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Bangunan (Gudang)'),
        backgroundColor: Colors.indigo.shade50,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bankBuildings.isEmpty
          ? const Center(
              child: Text('Bank kosong.\nBuat template bangunan di sini.'),
            )
          : ListView.builder(
              itemCount: _bankBuildings.length,
              itemBuilder: (c, i) {
                final dir = _bankBuildings[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.apartment, color: Colors.white),
                  ),
                  title: Text(p.basename(dir.path)),
                  subtitle: const Text('Status: Tersimpan di Bank'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'deploy') _deployBuilding(dir);
                      if (v == 'edit') _editBuilding(dir);
                      if (v == 'delete') _deleteBuilding(dir);
                    },
                    itemBuilder: (c) => [
                      const PopupMenuItem(
                        value: 'deploy',
                        child: Row(
                          children: [
                            Icon(Icons.ios_share, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Tempatkan (Deploy)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Isi'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _editBuilding(dir),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewBuilding,
        label: const Text('Buat Template Baru'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
