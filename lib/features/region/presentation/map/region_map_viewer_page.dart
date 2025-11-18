// lib/features/region/presentation/map/region_map_viewer_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
// --- PERUBAHAN: Import Peta Distrik ---
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
        // Cek eksistensi file gambar
        if (await _mapImageFile!.exists()) {
          final data = await _mapImageFile!.readAsBytes();
          final codec = await ui.instantiateImageCodec(data);
          final frame = await codec.getNextFrame();
          _imageAspectRatio = frame.image.width / frame.image.height;
        } else {
          _mapImageFile = null; // Reset jika file tidak ditemukan
        }
      }
      _placements = List<Map<String, dynamic>>.from(
        d['district_placements'] ?? [],
      );
      if (mounted) setState(() {});
    }
  }

  void _goToDistrictMap(String name) {
    final d = Directory(p.join(widget.regionDirectory.path, name));
    if (d.existsSync()) {
      // --- PERUBAHAN: Membuka Peta Distrik (Viewer), bukan Daftar ---
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
                          ..._placements.map(
                            (pl) => Positioned(
                              left: pl['map_x'] * cons.maxWidth - 15,
                              top: pl['map_y'] * cons.maxHeight - 15,
                              child: GestureDetector(
                                // Panggil fungsi navigasi ke MAP distrik
                                onTap: () => _goToDistrictMap(
                                  pl['district_folder_name'],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.holiday_village,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pl['district_folder_name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
