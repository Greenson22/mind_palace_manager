// lib/features/building/presentation/map/district_map_viewer_page.dart
// --- FILE BARU ---
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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

              // Pin Bangunan
              ..._placements.map((p) {
                final String name = p['building_folder_name'];
                final double x = p['map_x'];
                final double y = p['map_y'];

                return Positioned(
                  left: x * constraints.maxWidth - 20, // Setengah lebar marker
                  top: y * constraints.maxHeight - 40, // Tinggi marker
                  child: Tooltip(
                    message: name,
                    child: GestureDetector(
                      onTap: () => _navigateToBuilding(name),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4.0)],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
