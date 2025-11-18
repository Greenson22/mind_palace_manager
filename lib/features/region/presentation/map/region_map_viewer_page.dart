// lib/features/region/presentation/map/region_map_viewer_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_viewer_page.dart';

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

  // --- HELPER: Ambil Data Ikon Distrik ---
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

  // --- HELPER: Build Pin Widget (Sama seperti Editor) ---
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
                  const Icon(Icons.broken_image, size: 24),
            ),
          );
        }
      }
    }

    Widget pinContent;
    if (type == 'text' && iconData['data'] != null) {
      pinContent = Text(
        iconData['data'].toString(),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
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
            errorBuilder: (c, e, s) => const Icon(
              Icons.holiday_village,
              size: 14,
              color: Colors.white,
            ),
          ),
        );
      } else {
        pinContent = const Icon(
          Icons.holiday_village,
          size: 14,
          color: Colors.white,
        );
      }
    } else {
      pinContent = const Icon(
        Icons.holiday_village,
        size: 14,
        color: Colors.white,
      );
    }

    BoxDecoration pinDecoration;
    Color pinColor = Colors.red; // Warna Merah untuk Viewer

    // Logika Outline
    Border? borderDeco;
    if (AppSettings.showRegionPinOutline) {
      borderDeco = Border.all(color: Colors.white, width: 2);
    }

    if (AppSettings.mapPinShape == 'Kotak') {
      pinDecoration = BoxDecoration(
        color: pinColor,
        borderRadius: BorderRadius.circular(4),
        border: borderDeco,
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4.0)],
      );
    } else {
      pinDecoration = BoxDecoration(
        color: pinColor,
        shape: BoxShape.circle,
        border: borderDeco,
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

  // --- NAVIGASI ---
  void _goToDistrictMap(String name) {
    final d = Directory(p.join(widget.regionDirectory.path, name));
    if (d.existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => DistrictMapViewerPage(districtDirectory: d),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Distrik tidak ditemukan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Wilayah')),
      body: _mapImageFile == null
          ? const Center(child: Text('Tidak ada peta.'))
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
                            final name = pl['district_folder_name'];
                            return Positioned(
                              left: pl['map_x'] * cons.maxWidth - 15,
                              top: pl['map_y'] * cons.maxHeight - 15,
                              child: GestureDetector(
                                onTap: () => _goToDistrictMap(name),
                                child: Tooltip(
                                  message: name,
                                  child: FutureBuilder<Map<String, dynamic>>(
                                    future: _getDistrictIconData(name),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return _buildMapPinWidget({
                                          'type': null,
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
            ),
    );
  }
}
