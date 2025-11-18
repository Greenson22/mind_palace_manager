// lib/features/world/presentation/map/world_map_viewer_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
// --- UBAH: Import Viewer Peta Wilayah ---
import 'package:mind_palace_manager/features/region/presentation/map/region_map_viewer_page.dart';

class WorldMapViewerPage extends StatefulWidget {
  final Directory worldDirectory;
  const WorldMapViewerPage({super.key, required this.worldDirectory});

  @override
  State<WorldMapViewerPage> createState() => _WorldMapViewerPageState();
}

class _WorldMapViewerPageState extends State<WorldMapViewerPage> {
  File? _mapImageFile;
  List<Map<String, dynamic>> _placements = [];
  double _imageAspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final f = File(p.join(widget.worldDirectory.path, 'world_data.json'));
    if (await f.exists()) {
      try {
        final d = json.decode(await f.readAsString());
        if (d['map_image'] != null) {
          _mapImageFile = File(
            p.join(widget.worldDirectory.path, d['map_image']),
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
          d['region_placements'] ?? [],
        );
      } catch (e) {
        print("Error loading world map: $e");
      }
      if (mounted) setState(() {});
    }
  }

  Future<Map<String, dynamic>> _getRegionIconData(
    String regionFolderName,
  ) async {
    try {
      final regionDir = Directory(
        p.join(widget.worldDirectory.path, regionFolderName),
      );
      final jsonFile = File(p.join(regionDir.path, 'region_data.json'));
      if (!await jsonFile.exists()) return {'type': null, 'data': null};

      final content = await jsonFile.readAsString();
      final data = json.decode(content);
      final iconType = data['icon_type'];
      final iconData = data['icon_data'];

      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(regionDir.path, iconData.toString()));
        return {'type': 'image', 'file': imageFile};
      }
      return {'type': iconType, 'data': iconData};
    } catch (e) {
      return {'type': null, 'data': null};
    }
  }

  Widget _buildMapPinWidget(Map<String, dynamic> iconData, String regionName) {
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
        pinContent = Icon(Icons.public, size: 24, color: pinBaseColor);
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
        pinContent = const Icon(Icons.public, size: 18, color: Colors.white);
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
              regionName,
              style: TextStyle(color: nameColor, fontSize: 10),
            ),
          ),
        ],
      );
    }

    return pinContainer;
  }

  // --- UBAH: Navigasi ke Peta Wilayah ---
  void _goToRegionMap(String name) {
    final d = Directory(p.join(widget.worldDirectory.path, name));
    if (d.existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // Membuka Peta Wilayah, BUKAN Detail (Daftar)
          builder: (c) => RegionMapViewerPage(regionDirectory: d),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder wilayah tidak ditemukan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Dunia Ingatan'),
        actions: [
          // --- TAMBAHAN: Tombol Navigasi ke Daftar Wilayah ---
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Lihat Daftar Wilayah',
            onPressed: () {
              // Kembali ke halaman sebelumnya (biasanya BuildingManagementPage/Daftar)
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _mapImageFile == null
          ? const Center(child: Text('Tidak ada peta dunia.'))
          : InteractiveViewer(
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
                            final name = pl['region_folder_name'];

                            // --- BARU: Cek eksistensi folder wilayah ---
                            final regionDir = Directory(
                              p.join(widget.worldDirectory.path, name),
                            );
                            if (!regionDir.existsSync()) {
                              return const SizedBox.shrink();
                            }
                            // ------------------------------------------

                            return Positioned(
                              left: pl['map_x'] * cons.maxWidth - 20,
                              top: pl['map_y'] * cons.maxHeight - 20,
                              child: GestureDetector(
                                onTap: () => _goToRegionMap(name), // Ke MAP
                                child: Tooltip(
                                  message: name,
                                  child: FutureBuilder<Map<String, dynamic>>(
                                    future: _getRegionIconData(name),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return _buildMapPinWidget({
                                          'type': null,
                                        }, name);
                                      }
                                      return _buildMapPinWidget(
                                        snapshot.data!,
                                        name,
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
            ),
    );
  }
}
