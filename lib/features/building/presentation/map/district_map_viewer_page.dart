// lib/features/building/presentation/map/district_map_viewer_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui; // Tambahan import
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
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
  // --- TAMBAHAN: Rasio Aspek ---
  double _imageAspectRatio = 1.0;

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

      // --- TAMBAHAN: Baca dimensi gambar ---
      await _updateImageAspectRatio(_mapImageFile!);
    } catch (e) {
      _error = 'Gagal memuat data peta: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- TAMBAHAN: Helper ---
  Future<void> _updateImageAspectRatio(File imageFile) async {
    try {
      final data = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      setState(() {
        _imageAspectRatio = image.width / image.height;
      });
    } catch (e) {
      setState(() {
        _imageAspectRatio = 1.0;
      });
    }
  }

  void _navigateToBuilding(String buildingFolderName) {
    final buildingDir = Directory(
      p.join(widget.districtDirectory.path, buildingFolderName),
    );

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

      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(buildingDir.path, iconData.toString()));
        return {'type': 'image', 'file': imageFile};
      }

      return {'type': iconType, 'data': iconData};
    } catch (e) {
      return {'type': null, 'data': null};
    }
  }

  Widget _buildMapPinWidget(Map<String, dynamic> iconData) {
    final type = iconData['type'];
    if (AppSettings.mapPinShape == 'Tidak Ada (Tanpa Latar)') {
      if (type == 'image') {
        final File? imageFile = iconData['file'];
        if (imageFile != null) {
          return SizedBox(
            width: 30,
            height: 30,
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.image_not_supported, size: 24),
            ),
          );
        }
      }
    }
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
    const Color pinColor = Colors.red;
    BoxDecoration pinDecoration;
    if (AppSettings.mapPinShape == 'Kotak') {
      pinDecoration = BoxDecoration(
        color: pinColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4.0)],
      );
    } else {
      pinDecoration = BoxDecoration(
        color: pinColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4.0)],
      );
    }
    return Container(
      width: 30,
      height: 30,
      clipBehavior: Clip.antiAlias,
      decoration: pinDecoration,
      child: Center(child: pinContent),
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

    // --- STRUKTUR DIPERBARUI SAMAA SEPERTI EDITOR ---
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 5.0,
          child: Center(
            // Pastikan konten di tengah
            child: AspectRatio(
              aspectRatio: _imageAspectRatio, // Kunci utamanya
              child: LayoutBuilder(
                builder: (context, imageConstraints) {
                  // Stack sekarang berukuran PERSIS sama dengan rasio gambar
                  return Stack(
                    children: [
                      Image.file(
                        _mapImageFile!,
                        width: imageConstraints.maxWidth,
                        height: imageConstraints.maxHeight,
                        fit: BoxFit.cover, // Isi penuh box AspectRatio
                      ),
                      ..._placements.map((p) {
                        final String name = p['building_folder_name'];
                        final double x = p['map_x'];
                        final double y = p['map_y'];
                        return Positioned(
                          // Koordinat sekarang akurat terhadap gambar
                          left: x * imageConstraints.maxWidth - 15,
                          top: y * imageConstraints.maxHeight - 15,
                          child: Tooltip(
                            message: name,
                            child: GestureDetector(
                              onTap: () => _navigateToBuilding(name),
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: _getBuildingIconData(name),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return _buildMapPinWidget({
                                      'type': null,
                                      'data': null,
                                    });
                                  }
                                  return _buildMapPinWidget(snapshot.data!);
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
