// lib/features/region/presentation/map/region_map_viewer_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_viewer_page.dart';
import 'package:mind_palace_manager/features/region/presentation/management/region_detail_page.dart';

// --- IMPORT TRANSISI AWAN ---
import 'package:mind_palace_manager/features/settings/helpers/cloud_transition.dart';

class RegionMapViewerPage extends StatefulWidget {
  final Directory regionDirectory;
  const RegionMapViewerPage({super.key, required this.regionDirectory});

  @override
  State<RegionMapViewerPage> createState() => _RegionMapViewerPageState();
}

class _RegionMapViewerPageState extends State<RegionMapViewerPage> {
  File? _mapImageFile;
  List<Map<String, dynamic>> _placements = [];
  double _imageAspectRatio = 1.0;

  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final f = File(p.join(widget.regionDirectory.path, 'region_data.json'));
    if (await f.exists()) {
      final d = json.decode(await f.readAsString());
      if (d['map_image'] != null) {
        _mapImageFile = File(
          p.join(widget.regionDirectory.path, d['map_image']),
        );
        if (await _mapImageFile!.exists()) {
          final data = await _mapImageFile!.readAsBytes();
          final codec = await ui.instantiateImageCodec(data);
          final frame = await codec.getNextFrame();
          _imageAspectRatio = frame.image.width / frame.image.height;
        } else {
          _mapImageFile = null;
        }
      }
      _placements = List<Map<String, dynamic>>.from(
        d['district_placements'] ?? [],
      );
      if (mounted) setState(() {});
    }
  }

  Future<Map<String, dynamic>> _getDistrictIconData(
    String districtFolderName,
  ) async {
    try {
      final districtDir = Directory(
        p.join(widget.regionDirectory.path, districtFolderName),
      );
      final jsonFile = File(p.join(districtDir.path, 'district_data.json'));
      if (!await jsonFile.exists()) return {'type': null, 'data': null};

      final content = await jsonFile.readAsString();
      final data = json.decode(content);
      final iconType = data['icon_type'];
      final iconData = data['icon_data'];

      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(districtDir.path, iconData.toString()));
        return {'type': 'image', 'file': imageFile};
      }
      return {'type': iconType, 'data': iconData};
    } catch (e) {
      return {'type': null, 'data': null};
    }
  }

  Widget _buildMapPinWidget(
    Map<String, dynamic> iconData,
    String districtName,
  ) {
    final type = iconData['type'];
    final shape = AppSettings.regionPinShape;
    final Color pinBaseColor = Color(AppSettings.regionPinColor);
    final Color outlineColor = Color(AppSettings.regionOutlineColor);
    final Color nameColor = Color(AppSettings.regionNameColor);

    Widget pinContent;
    if (shape == 'Tidak Ada (Tanpa Latar)') {
      if (type == 'image' && iconData['file'] != null) {
        pinContent = SizedBox(
          width: 30,
          height: 30,
          child: Image.file(iconData['file'], fit: BoxFit.contain),
        );
      } else if (type == 'text' && iconData['data'] != null) {
        pinContent = Text(
          iconData['data'],
          style: TextStyle(
            fontSize: 16,
            color: nameColor,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
          ),
          textAlign: TextAlign.center,
        );
      } else {
        pinContent = Icon(Icons.holiday_village, size: 24, color: pinBaseColor);
      }
    } else {
      if (type == 'text' && iconData['data'] != null) {
        pinContent = Text(
          iconData['data'],
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        );
      } else if (type == 'image' && iconData['file'] != null) {
        if (shape == 'Kotak') {
          pinContent = Image.file(
            iconData['file'],
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          );
        } else {
          pinContent = ClipOval(
            child: Image.file(
              iconData['file'],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          );
        }
      } else {
        pinContent = const Icon(
          Icons.holiday_village,
          size: 18,
          color: Colors.white,
        );
      }
    }

    Widget pinContainer = pinContent;

    if (shape != 'Tidak Ada (Tanpa Latar)') {
      Border? borderDeco;
      if (AppSettings.showRegionPinOutline) {
        borderDeco = Border.all(
          color: outlineColor,
          width: AppSettings.regionPinOutlineWidth,
        );
      }

      pinContainer = Container(
        width: 32 + AppSettings.regionPinShapeStrokeWidth * 2,
        height: 32 + AppSettings.regionPinShapeStrokeWidth * 2,
        padding: EdgeInsets.all(
          AppSettings.regionPinShapeStrokeWidth > 0
              ? AppSettings.regionPinShapeStrokeWidth
              : 0,
        ),
        decoration: BoxDecoration(
          color: pinBaseColor,
          shape: shape == 'Kotak' ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: shape == 'Kotak' ? BorderRadius.circular(4) : null,
          border: borderDeco,
          boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4.0)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(child: pinContent),
      );
    }

    if (AppSettings.showRegionDistrictNames) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          pinContainer,
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              districtName,
              style: TextStyle(color: nameColor, fontSize: 10),
            ),
          ),
        ],
      );
    }

    return pinContainer;
  }

  void _goToDistrictMap(String name) {
    final d = Directory(p.join(widget.regionDirectory.path, name));
    if (d.existsSync()) {
      // --- MENGGUNAKAN CLOUD TRANSITION ---
      CloudNavigation.push(
        context,
        DistrictMapViewerPage(districtDirectory: d),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Distrik tidak ditemukan')));
    }
  }

  void _openDistrictList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) =>
            RegionDetailPage(regionDirectory: widget.regionDirectory),
      ),
    );
  }

  // --- EXPORT FUNCTIONS ---
  Future<void> _exportMapImage() async {
    if (_mapImageFile == null) return;
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
      final regionName = p.basename(widget.regionDirectory.path);
      final fileName =
          'region_map_export_png_${regionName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.png';
      final file = File(p.join(AppSettings.exportPath!, fileName));

      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Peta berhasil diexport ke: ${file.path}'),
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
      final regionName = p.basename(widget.regionDirectory.path);
      final fileName = p.basename(_mapImageFile!.path);
      final now = DateTime.now();
      final newFileName =
          'region_map_original_${regionName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}${p.extension(fileName)}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Peta Wilayah',
          style: TextStyle(
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
                _openDistrictList();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'list',
                child: Row(
                  children: [
                    Icon(Icons.list_alt),
                    SizedBox(width: 8),
                    Text('Lihat Daftar Distrik'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export_png',
                child: Row(
                  children: [
                    Icon(Icons.ios_share),
                    SizedBox(width: 8),
                    Text('Export Peta (PNG Screenshot)'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'export_original',
                enabled: _mapImageFile != null,
                child: Row(
                  children: [
                    const Icon(Icons.file_copy, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      _mapImageFile != null
                          ? 'Export File Asli Peta'
                          : 'Tidak Ada File Peta',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RepaintBoundary(
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
    if (_mapImageFile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text('Tidak ada peta.', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Center(
        child: AspectRatio(
          aspectRatio: _imageAspectRatio,
          child: LayoutBuilder(
            builder: (c, cons) {
              return Stack(
                children: [
                  Image.file(
                    _mapImageFile!,
                    width: cons.maxWidth,
                    height: cons.maxHeight,
                    fit: BoxFit.cover,
                  ),
                  ..._placements.map((pl) {
                    final name = pl['district_folder_name'];
                    final districtDir = Directory(
                      p.join(widget.regionDirectory.path, name),
                    );
                    if (!districtDir.existsSync()) {
                      return const SizedBox.shrink();
                    }

                    return Positioned(
                      left: pl['map_x'] * cons.maxWidth - 20,
                      top: pl['map_y'] * cons.maxHeight - 20,
                      child: GestureDetector(
                        onTap: () => _goToDistrictMap(name),
                        child: Tooltip(
                          message: name,
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: _getDistrictIconData(name),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return _buildMapPinWidget({'type': null}, name);
                              }
                              return _buildMapPinWidget(snapshot.data!, name);
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
  }
}
