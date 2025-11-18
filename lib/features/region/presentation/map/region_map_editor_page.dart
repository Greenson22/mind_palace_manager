// lib/features/region/presentation/map/region_map_editor_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class RegionMapEditorPage extends StatefulWidget {
  final Directory regionDirectory;
  const RegionMapEditorPage({super.key, required this.regionDirectory});

  @override
  State<RegionMapEditorPage> createState() => _RegionMapEditorPageState();
}

class _RegionMapEditorPageState extends State<RegionMapEditorPage> {
  late File _jsonFile;
  Map<String, dynamic> _regionData = {
    "map_image": null,
    "district_placements": [],
  };
  List<Directory> _districtFolders = [];

  String? _mapImageName;
  File? _mapImageFile;
  List<Map<String, dynamic>> _placements = [];
  Directory? _selectedDistrictToPlace;
  Offset? _tappedRelativeCoords;
  double _imageAspectRatio = 1.0;

  // Controller untuk Zoom
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.regionDirectory.path, 'region_data.json'));
    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (await _jsonFile.exists()) {
      final content = await _jsonFile.readAsString();
      _regionData = json.decode(content);
      _mapImageName = _regionData['map_image'];
      _placements = List<Map<String, dynamic>>.from(
        _regionData['district_placements'] ?? [],
      );
      if (_mapImageName != null) {
        _mapImageFile = File(
          p.join(widget.regionDirectory.path, _mapImageName!),
        );
        await _updateImageAspectRatio(_mapImageFile!);
      }
    }
    final entities = await widget.regionDirectory.list().toList();
    _districtFolders = entities.whereType<Directory>().toList();
    if (mounted) setState(() {});
  }

  Future<void> _updateImageAspectRatio(File imageFile) async {
    try {
      final data = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(
          () => _imageAspectRatio = frame.image.width / frame.image.height,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _imageAspectRatio = 1.0);
    }
  }

  Future<void> _saveData() async {
    _regionData['map_image'] = _mapImageName;
    _regionData['district_placements'] = _placements;
    await _jsonFile.writeAsString(json.encode(_regionData));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perubahan disimpan!')));
    }
  }

  Future<void> _pickMapImage() async {
    var res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null) {
      final src = File(res.files.single.path!);
      final name = p.basename(src.path);
      await src.copy(p.join(widget.regionDirectory.path, name));
      _mapImageName = name;
      _mapImageFile = File(p.join(widget.regionDirectory.path, name));
      await _updateImageAspectRatio(_mapImageFile!);
      _saveData();
      setState(() {});
    }
  }

  void _placeDistrict() {
    if (_selectedDistrictToPlace == null || _tappedRelativeCoords == null) {
      return;
    }
    final name = p.basename(_selectedDistrictToPlace!.path);
    // Hapus penempatan lama jika ada
    _placements.removeWhere((x) => x['district_folder_name'] == name);
    _placements.add({
      'district_folder_name': name,
      'map_x': _tappedRelativeCoords!.dx,
      'map_y': _tappedRelativeCoords!.dy,
    });
    _selectedDistrictToPlace = null;
    _tappedRelativeCoords = null;
    _saveData();
    setState(() {});
  }

  void _removePlacement(String name) {
    setState(() {
      _placements.removeWhere((x) => x['district_folder_name'] == name);
    });
    _saveData();
  }

  // --- LOGIKA ZOOM ---
  void _zoomIn() {
    final Matrix4 matrix = _transformationController.value.clone();
    matrix.scale(1.2);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final Matrix4 matrix = _transformationController.value.clone();
    matrix.scale(1 / 1.2);
    _transformationController.value = matrix;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // --- HELPER IKON ---
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
    Color pinColor = Colors.blue; // Warna Biru untuk Editor

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor Peta Wilayah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            onPressed: _pickMapImage,
            label: Text(_mapImageFile == null ? 'Pilih Peta' : 'Ganti Peta'),
          ),
          const SizedBox(height: 16),
          DropdownButton<Directory>(
            value: _selectedDistrictToPlace,
            hint: const Text('Pilih Distrik untuk ditempatkan'),
            isExpanded: true,
            items: _districtFolders.map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text(p.basename(d.path)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedDistrictToPlace = v),
          ),
          const SizedBox(height: 8),
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.black12,
            ),
            child: _mapImageFile == null
                ? const Center(child: Text('Belum ada gambar peta'))
                : Stack(
                    children: [
                      InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 6.0,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _imageAspectRatio,
                            child: LayoutBuilder(
                              builder: (ctx, cons) {
                                return GestureDetector(
                                  onTapDown: (d) {
                                    final local = d.localPosition;
                                    setState(
                                      () => _tappedRelativeCoords = Offset(
                                        local.dx / cons.maxWidth,
                                        local.dy / cons.maxHeight,
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        _mapImageFile!,
                                        width: cons.maxWidth,
                                        height: cons.maxHeight,
                                        fit: BoxFit.cover,
                                      ),
                                      // Render Pin
                                      ..._placements.map((pl) {
                                        final name = pl['district_folder_name'];
                                        return Positioned(
                                          left:
                                              pl['map_x'] * cons.maxWidth - 15,
                                          top:
                                              pl['map_y'] * cons.maxHeight - 15,
                                          child:
                                              FutureBuilder<
                                                Map<String, dynamic>
                                              >(
                                                future: _getDistrictIconData(
                                                  name,
                                                ),
                                                builder: (c, s) {
                                                  if (!s.hasData) {
                                                    return _buildMapPinWidget({
                                                      'type': null,
                                                    });
                                                  }
                                                  return _buildMapPinWidget(
                                                    s.data!,
                                                  );
                                                },
                                              ),
                                        );
                                      }),
                                      // Penanda posisi tap baru
                                      if (_tappedRelativeCoords != null)
                                        Positioned(
                                          left:
                                              _tappedRelativeCoords!.dx *
                                                  cons.maxWidth -
                                              15,
                                          top:
                                              _tappedRelativeCoords!.dy *
                                                  cons.maxHeight -
                                              30,
                                          child: const Icon(
                                            Icons.add_location,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      // Tombol Zoom Overlay
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'zoom_in',
                              onPressed: _zoomIn,
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'zoom_out',
                              onPressed: _zoomOut,
                              child: const Icon(Icons.remove),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'reset',
                              backgroundColor: Colors.grey.shade200,
                              onPressed: _resetZoom,
                              child: const Icon(
                                Icons.center_focus_strong,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed:
                  (_selectedDistrictToPlace != null &&
                      _tappedRelativeCoords != null)
                  ? _placeDistrict
                  : null,
              label: const Text('Tempatkan / Update Posisi Distrik'),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Daftar Distrik Terpasang:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._placements.map((p) {
            final name = p['district_folder_name'];
            return ListTile(
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removePlacement(name),
                tooltip: 'Hapus dari peta',
              ),
            );
          }),
        ],
      ),
    );
  }
}
