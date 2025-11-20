// lib/features/building/presentation/map/district_map_viewer_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';
import 'package:mind_palace_manager/features/building/presentation/management/district_building_management_page.dart';

// --- IMPORT TRANSISI AWAN ---
import 'package:mind_palace_manager/features/settings/helpers/cloud_transition.dart';

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
  double _imageAspectRatio = 1.0;

  final GlobalKey _globalKey = GlobalKey();

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
        data['building_placements'] ?? [],
      );
      final mapImageName = data['map_image'];

      if (mapImageName != null) {
        _mapImageFile = File(
          p.join(widget.districtDirectory.path, mapImageName),
        );
        if (await _mapImageFile!.exists()) {
          await _updateImageAspectRatio(_mapImageFile!);
        } else {
          _mapImageFile = null;
        }
      }
    } catch (e) {
      _error = 'Gagal memuat data peta: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateImageAspectRatio(File imageFile) async {
    try {
      final data = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      if (mounted) {
        setState(() {
          _imageAspectRatio = image.width / image.height;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageAspectRatio = 1.0;
        });
      }
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

    // --- MENGGUNAKAN CLOUD TRANSITION ---
    CloudNavigation.push(
      context,
      BuildingViewerPage(buildingDirectory: buildingDir),
    );
  }

  void _openBuildingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DistrictBuildingManagementPage(
          districtDirectory: widget.districtDirectory,
        ),
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

  Widget _buildMapPinWidget(Map<String, dynamic> iconData, double size) {
    final type = iconData['type'];
    Widget pinContent;

    if (type == 'text' &&
        iconData['data'] != null &&
        iconData['data'].toString().isNotEmpty) {
      pinContent = Text(
        iconData['data'].toString(),
        style: TextStyle(
          fontSize: size * 0.5,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.clip,
      );
    } else if (type == 'image') {
      final File? imageFile = iconData['file'];
      if (imageFile != null) {
        if (AppSettings.mapPinShape == 'Tidak Ada (Tanpa Latar)') {
          return SizedBox(
            width: size,
            height: size,
            child: Image.file(imageFile, fit: BoxFit.contain),
          );
        }
        pinContent = Image.file(
          imageFile,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              Icon(Icons.location_city, size: size * 0.6, color: Colors.white),
        );
      } else {
        pinContent = Icon(
          Icons.location_city,
          size: size * 0.6,
          color: Colors.white,
        );
      }
    } else {
      pinContent = Icon(
        Icons.location_city,
        size: size * 0.6,
        color: Colors.white,
      );
    }

    if (AppSettings.mapPinShape == 'Tidak Ada (Tanpa Latar)') {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: pinContent),
      );
    }

    const Color pinColor = Colors.blue;
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
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: pinDecoration,
      child: Center(child: pinContent),
    );
  }

  // --- EXPORT FUNCTIONS ---

  Future<void> _exportMapImage() async {
    if (AppSettings.exportPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atur folder export di Pengaturan terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Capture RepaintBoundary (Termasuk background & overlay)
      final boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Gagal menemukan RenderBoundary.');
      }

      const pixelRatio = 3.0;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final now = DateTime.now();
      final districtName = p.basename(widget.districtDirectory.path);
      final fileName =
          'district_map_export_png_${districtName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.png';
      final file = File(p.join(AppSettings.exportPath!, fileName));

      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tampilan peta berhasil diexport ke: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export peta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportOriginalMapFile() async {
    if (_mapImageFile == null || !await _mapImageFile!.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File gambar peta asli tidak ditemukan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (AppSettings.exportPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atur folder export di Pengaturan terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final districtName = p.basename(widget.districtDirectory.path);
      final fileName = p.basename(_mapImageFile!.path);
      final now = DateTime.now();
      final newFileName =
          'district_map_original_${districtName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}${p.extension(fileName)}';
      final destinationPath = p.join(AppSettings.exportPath!, newFileName);

      await _mapImageFile!.copy(destinationPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File peta asli berhasil diexport ke: ${destinationPath}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export file peta asli: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================================
  // BUILDER METHODS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final districtName = p.basename(widget.districtDirectory.path);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Peta: $districtName',
          style: const TextStyle(
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            onSelected: (String value) {
              if (value == 'export_png') {
                _exportMapImage();
              } else if (value == 'export_original') {
                _exportOriginalMapFile();
              } else if (value == 'list') {
                _openBuildingList();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'list',
                child: Row(
                  children: [
                    Icon(Icons.list_alt),
                    SizedBox(width: 8),
                    Text('Lihat Daftar Bangunan'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_png',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Export Tampilan (PNG Screenshot)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_original',
                enabled: true,
                child: Row(
                  children: [
                    Icon(Icons.image, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Export File Asli Peta'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : RepaintBoundary(
              key: _globalKey,
              child: Stack(
                children: [
                  _buildImmersiveBackground(),
                  _buildOverlay(),
                  _buildInteractiveMap(),
                ],
              ),
            ),
    );
  }

  Widget _buildImmersiveBackground() {
    if (_mapImageFile != null && _mapImageFile!.existsSync()) {
      return ValueListenableBuilder<double>(
        valueListenable: AppSettings.blurStrength,
        builder: (context, blur, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  _mapImageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(color: Colors.black.withOpacity(0)),
                ),
              ),
            ],
          );
        },
      );
    }

    final mode = AppSettings.wallpaperMode;

    if (mode == 'gradient') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppSettings.gradientColor1),
              Color(AppSettings.gradientColor2),
            ],
          ),
        ),
      );
    } else if (mode == 'solid') {
      return ValueListenableBuilder<int>(
        valueListenable: AppSettings.solidColor,
        builder: (context, colorVal, child) {
          return Container(color: Color(colorVal));
        },
      );
    }

    return Container(color: Theme.of(context).scaffoldBackgroundColor);
  }

  Widget _buildOverlay() {
    return ValueListenableBuilder<double>(
      valueListenable: AppSettings.backgroundOverlayOpacity,
      builder: (context, opacity, child) {
        return Container(color: Colors.black.withOpacity(opacity));
      },
    );
  }

  Widget _buildInteractiveMap() {
    if (_mapImageFile == null || !_mapImageFile!.existsSync()) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Gambar peta tidak ditemukan.',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 5.0,
          child: Center(
            child: AspectRatio(
              aspectRatio: _imageAspectRatio,
              child: LayoutBuilder(
                builder: (context, imageConstraints) {
                  return Stack(
                    children: [
                      Image.file(
                        _mapImageFile!,
                        width: imageConstraints.maxWidth,
                        height: imageConstraints.maxHeight,
                        fit: BoxFit.cover,
                      ),
                      ..._placements.map((item) {
                        final String name = item['building_folder_name'];
                        final double x = item['map_x'];
                        final double y = item['map_y'];
                        final double size = item['size'] != null
                            ? (item['size'] as num).toDouble()
                            : 30.0;

                        final buildingDir = Directory(
                          p.join(widget.districtDirectory.path, name),
                        );
                        if (!buildingDir.existsSync()) {
                          return const SizedBox.shrink();
                        }

                        return Positioned(
                          left: x * imageConstraints.maxWidth - (size / 2),
                          top: y * imageConstraints.maxHeight - (size / 2),
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
                                    }, size);
                                  }
                                  return _buildMapPinWidget(
                                    snapshot.data!,
                                    size,
                                  );
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
