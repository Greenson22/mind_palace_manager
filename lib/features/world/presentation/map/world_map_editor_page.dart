// lib/features/world/presentation/map/world_map_editor_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class WorldMapEditorPage extends StatefulWidget {
  final Directory worldDirectory;
  const WorldMapEditorPage({super.key, required this.worldDirectory});

  @override
  State<WorldMapEditorPage> createState() => _WorldMapEditorPageState();
}

class _WorldMapEditorPageState extends State<WorldMapEditorPage> {
  late File _jsonFile;
  Map<String, dynamic> _worldData = {
    "map_image": null,
    "region_placements": [],
  };
  List<Directory> _regionFolders = [];

  String? _mapImageName;
  File? _mapImageFile;
  List<Map<String, dynamic>> _placements = [];
  Directory? _selectedRegionToPlace;
  Offset? _tappedRelativeCoords;
  double _imageAspectRatio = 1.0;

  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    // Simpan di root folder dengan nama world_data.json
    _jsonFile = File(p.join(widget.worldDirectory.path, 'world_data.json'));
    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (await _jsonFile.exists()) {
      try {
        final content = await _jsonFile.readAsString();
        _worldData = json.decode(content);
        _mapImageName = _worldData['map_image'];
        _placements = List<Map<String, dynamic>>.from(
          _worldData['region_placements'] ?? [],
        );
        if (_mapImageName != null) {
          _mapImageFile = File(
            p.join(widget.worldDirectory.path, _mapImageName!),
          );
          await _updateImageAspectRatio(_mapImageFile!);
        }
      } catch (e) {
        print("Error loading world data: $e");
      }
    }
    // Muat daftar wilayah
    try {
      final entities = await widget.worldDirectory.list().toList();
      _regionFolders = entities.whereType<Directory>().toList();
    } catch (e) {
      print("Error loading regions: $e");
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateImageAspectRatio(File imageFile) async {
    try {
      if (!await imageFile.exists()) return;
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
    _worldData['map_image'] = _mapImageName;
    _worldData['region_placements'] = _placements;
    await _jsonFile.writeAsString(json.encode(_worldData));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Peta Dunia disimpan!')));
    }
  }

  Future<void> _pickMapImage() async {
    var res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null) {
      final src = File(res.files.single.path!);
      final extension = p.extension(src.path);

      // --- BARU: Gunakan nama file tetap ---
      const baseName = 'world_map';
      final newFixedFileName = '$baseName$extension';

      final String? oldMapImageName = _mapImageName;

      // 1. Copy file baru ke nama tetap. Ini akan menimpa jika nama sama.
      final destPath = p.join(widget.worldDirectory.path, newFixedFileName);
      await src.copy(destPath);

      // 2. Hapus file lama jika namanya berbeda (mencegah penumpukan file dengan ekstensi berbeda)
      if (oldMapImageName != null && oldMapImageName != newFixedFileName) {
        try {
          final oldFile = File(
            p.join(widget.worldDirectory.path, oldMapImageName),
          );
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          print("Failed to delete old world map image: $e");
        }
      }

      // 3. Update state variables
      _mapImageName = newFixedFileName;
      _mapImageFile = File(destPath);
      await _updateImageAspectRatio(_mapImageFile!);

      // 4. Save data dan refresh UI
      _saveData();
      setState(() {});
    }
  }

  void _placeRegion() {
    if (_selectedRegionToPlace == null || _tappedRelativeCoords == null) {
      return;
    }
    final name = p.basename(_selectedRegionToPlace!.path);
    _placements.removeWhere((x) => x['region_folder_name'] == name);
    _placements.add({
      'region_folder_name': name,
      'map_x': _tappedRelativeCoords!.dx,
      'map_y': _tappedRelativeCoords!.dy,
    });
    _selectedRegionToPlace = null;
    _tappedRelativeCoords = null;
    _saveData();
    setState(() {});
  }

  void _removePlacement(String name) {
    setState(() {
      _placements.removeWhere((x) => x['region_folder_name'] == name);
    });
    _saveData();
  }

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

  // Helper: Ambil ikon dari folder wilayah (region_data.json)
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
    // Kita gunakan setting yang sama dengan Region Pin untuk konsistensi
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor Peta Dunia')),
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
            value: _selectedRegionToPlace,
            hint: const Text('Pilih Wilayah untuk ditempatkan'),
            isExpanded: true,
            items: _regionFolders.map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text(p.basename(d.path)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedRegionToPlace = v),
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
                                      ..._placements.map((pl) {
                                        final name = pl['region_folder_name'];
                                        return Positioned(
                                          left:
                                              pl['map_x'] * cons.maxWidth - 20,
                                          top:
                                              pl['map_y'] * cons.maxHeight - 20,
                                          child:
                                              FutureBuilder<
                                                Map<String, dynamic>
                                              >(
                                                future: _getRegionIconData(
                                                  name,
                                                ),
                                                builder: (c, s) {
                                                  if (!s.hasData) {
                                                    return _buildMapPinWidget({
                                                      'type': null,
                                                    }, name);
                                                  }
                                                  return _buildMapPinWidget(
                                                    s.data!,
                                                    name,
                                                  );
                                                },
                                              ),
                                        );
                                      }),
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
                  (_selectedRegionToPlace != null &&
                      _tappedRelativeCoords != null)
                  ? _placeRegion
                  : null,
              label: const Text('Tempatkan / Update Posisi'),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Daftar Wilayah Terpasang:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._placements.map((p) {
            final name = p['region_folder_name'];
            return ListTile(
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removePlacement(name),
                tooltip: 'Hapus',
              ),
            );
          }),
        ],
      ),
    );
  }
}
