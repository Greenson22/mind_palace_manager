// lib/features/building/presentation/management/building_management_page.dart
// --- FILE INI DIUBAH TOTAL ---

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert'; // <-- TAMBAHAN IMPORT
import 'package:mind_palace_manager/app_settings.dart';
// Import halaman baru yang kita buat
import 'package:mind_palace_manager/features/building/presentation/management/district_building_management_page.dart';
// --- TAMBAHAN ---
import 'package:mind_palace_manager/features/building/presentation/map/district_map_editor_page.dart';
// --- SELESAI TAMBAHAN ---
import 'package:mind_palace_manager/permission_helper.dart';

// Nama kelas tetap, tapi fungsinya berubah
class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  // Variabel ini sekarang menyimpan folder Distrik
  List<Directory> _districtFolders = [];
  bool _isLoading = false;
  // Controller untuk membuat distrik baru
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

  // Fungsi ini sekarang memuat Distrik dari AppSettings.baseBuildingsPath
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

  // Dialog untuk membuat Distrik baru
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

  // Logika untuk membuat folder Distrik baru
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

      // --- TAMBAHAN: Buat district_data.json ---
      final dataJsonFile = File(p.join(newDistrictPath, 'district_data.json'));
      // Inisialisasi data peta
      await dataJsonFile.writeAsString(
        json.encode({
          "map_image": null, // Path ke gambar peta
          "building_placements": [], // List penempatan bangunan
        }),
      );
      // --- SELESAI TAMBAHAN ---

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

  // Navigasi ke halaman detail distrik (daftar bangunan)
  void _viewDistrict(Directory districtDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DistrictBuildingManagementPage(districtDirectory: districtDir),
      ),
    );
  }

  // --- TAMBAHAN: Navigasi ke Editor Peta ---
  void _editDistrictMap(Directory districtDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DistrictMapEditorPage(districtDirectory: districtDir),
      ),
    );
  }
  // --- SELESAI TAMBAHAN ---

  // Logika menghapus Distrik
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
        title: const Text('Manajemen Distrik'), // AppBar diubah
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
        child: const Icon(Icons.add_location_alt), // Ikon diubah
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

    // Ini adalah daftar Distrik
    return ListView.builder(
      itemCount: _districtFolders.length,
      itemBuilder: (context, index) {
        final folder = _districtFolders[index];
        final folderName = p.basename(folder.path);
        return ListTile(
          leading: const Icon(Icons.holiday_village, size: 40), // Ikon diubah
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- TAMBAHAN: Tombol Edit Peta ---
              IconButton(
                icon: const Icon(Icons.map, color: Colors.blue),
                tooltip: 'Edit Peta Distrik',
                onPressed: () => _editDistrictMap(folder),
              ),
              // --- SELESAI TAMBAHAN ---
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Hapus Distrik',
                onPressed: () => _deleteDistrict(folder),
              ),
            ],
          ),
          // Aksi utama adalah masuk ke dalam distrik
          onTap: () => _viewDistrict(folder),
        );
      },
    );
  }
}
