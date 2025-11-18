// lib/features/building/presentation/map/district_map_viewer_page.dart
// --- FILE DIPERBARUI ---
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
// --- TAMBAHAN ---
import 'package:mind_palace_manager/app_settings.dart';
// --- SELESAI TAMBAHAN ---
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';

class DistrictMapViewerPage extends StatefulWidget {
  final Directory districtDirectory;

  const DistrictMapViewerPage({super.key, required this.districtDirectory});

  @override
  State<DistrictMapViewerPage> createState() => _DistrictMapViewerPageState();
}

class _DistrictMapViewerPageState extends State<DistrictMapViewerPage> {
  late File _jsonFile;
  bool _isLoading = true;
  String? _error;

  File? _mapImageFile;
  List<Map<String, dynamic>> _placements = [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(
      p.join(widget.districtDirectory.path, 'district_data.json'),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!await _jsonFile.exists()) {
        throw Exception('File district_data.json tidak ditemukan.');
      }
      final content = await _jsonFile.readAsString();
      final data = json.decode(content);

      _placements = List<Map<String, dynamic>>.from(
        data['building_placements'],
      );
      final mapImageName = data['map_image'];

      if (mapImageName == null) {
        throw Exception('Gambar peta belum diatur untuk distrik ini.');
      }

      _mapImageFile = File(p.join(widget.districtDirectory.path, mapImageName));
      if (!await _mapImageFile!.exists()) {
        throw Exception('File gambar peta "$mapImageName" tidak ditemukan.');
      }
    } catch (e) {
      _error = 'Gagal memuat data peta: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToBuilding(String buildingFolderName) {
    // Bangun path lengkap ke folder bangunan
    final buildingDir = Directory(
      p.join(widget.districtDirectory.path, buildingFolderName),
    );

    // Cek apakah folder itu ada (sebagai pengaman)
    if (!buildingDir.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Folder bangunan "$buildingFolderName" tidak ditemukan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BuildingViewerPage(buildingDirectory: buildingDir),
      ),
    );
  }

  // --- FUNGSI HELPER BARU (diambil dari management_page) ---
  /// Membaca data.json dari folder bangunan untuk mendapatkan info ikon.
  Future<Map<String, dynamic>> _getBuildingIconData(
    String buildingFolderName,
  ) async {
    try {
      final buildingDir = Directory(
        p.join(widget.districtDirectory.path, buildingFolderName),
      );
      final jsonFile = File(p.join(buildingDir.path, 'data.json'));
      if (!await jsonFile.exists()) {
        return {'type': null, 'data': null};
      }

      final content = await jsonFile.readAsString();
      final data = json.decode(content);

      final iconType = data.containsKey('icon_type') ? data['icon_type'] : null;
      final iconData = data.containsKey('icon_data') ? data['icon_data'] : null;

      // Untuk gambar, kita butuh path lengkap
      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(buildingDir.path, iconData.toString()));
        return {'type': 'image', 'file': imageFile}; // Kembalikan File
      }

      return {'type': iconType, 'data': iconData};
    } catch (e) {
      print('Gagal membaca ikon: $e');
      return {'type': null, 'data': null};
    }
  }

  // --- FUNGSI HELPER BARU ---
  /// Membuat widget pin kustom
  Widget _buildMapPinWidget(Map<String, dynamic> iconData) {
    final type = iconData['type'];

    Widget pinContent;

    if (type == 'text' &&
        iconData['data'] != null &&
        iconData['data'].toString().isNotEmpty) {
      pinContent = Text(
        iconData['data'].toString(),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.clip,
      );
    } else if (type == 'image') {
      final File? imageFile = iconData['file'];
      if (imageFile != null) {
        pinContent = ClipOval(
          // Gambar di dalam pin selalu bulat agar rapi
          child: Image.file(
            imageFile,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.location_city, size: 14, color: Colors.white),
          ),
        );
      } else {
        pinContent = const Icon(
          Icons.location_city,
          size: 14,
          color: Colors.white,
        );
      }
    } else {
      pinContent = const Icon(
        Icons.location_city,
        size: 14,
        color: Colors.white,
      );
    }

    // Tentukan warna pin
    const Color pinColor = Colors.red; // Merah untuk viewer

    // Tentukan dekorasi berdasarkan AppSettings
    BoxDecoration pinDecoration;

    if (AppSettings.iconShape == 'Bulat') {
      pinDecoration = BoxDecoration(
        color: pinColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4.0)],
      );
    } else {
      // 'Kotak' atau 'Tidak Ada' (default ke Kotak di peta agar terlihat)
      pinDecoration = BoxDecoration(
        color: pinColor,
        borderRadius: BorderRadius.circular(4), // Menjadi kotak
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4.0)],
      );
    }

    // Container pin
    return Container(
      width: 30,
      height: 30,
      clipBehavior: Clip.antiAlias, // Selalu potong
      decoration: pinDecoration,
      child: Center(child: pinContent),
    );
  }
  // --- SELESAI FUNGSI HELPER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peta: ${p.basename(widget.districtDirectory.path)}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 5.0,
          child: Stack(
            children: [
              // Gambar Peta
              Image.file(
                _mapImageFile!,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: BoxFit.contain,
              ),

              // --- PERUBAHAN RENDER PIN ---
              // Pin Bangunan
              ..._placements.map((p) {
                final String name = p['building_folder_name'];
                final double x = p['map_x'];
                final double y = p['map_y'];

                return Positioned(
                  // Pusatkan pin di koordinat x/y
                  left:
                      x * constraints.maxWidth - 15, // 15 = setengah lebar pin
                  top:
                      y * constraints.maxHeight -
                      15, // 15 = setengah tinggi pin
                  child: Tooltip(
                    message: name,
                    child: GestureDetector(
                      onTap: () => _navigateToBuilding(name),
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _getBuildingIconData(name),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            // Pin default saat loading
                            return _buildMapPinWidget({
                              'type': null,
                              'data': null,
                            });
                          }
                          // Pin kustom
                          return _buildMapPinWidget(snapshot.data!);
                        },
                      ),
                    ),
                  ),
                );
              }),
              // --- SELESAI PERUBAHAN RENDER PIN ---
            ],
          ),
        );
      },
    );
  }
}
