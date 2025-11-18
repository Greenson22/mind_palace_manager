// lib/features/building/presentation/map/district_map_editor_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class DistrictMapEditorPage extends StatefulWidget {
  final Directory districtDirectory;

  const DistrictMapEditorPage({super.key, required this.districtDirectory});

  @override
  State<DistrictMapEditorPage> createState() => _DistrictMapEditorPageState();
}

class _DistrictMapEditorPageState extends State<DistrictMapEditorPage> {
  late File _jsonFile;
  Map<String, dynamic> _districtData = {
    "map_image": null,
    "building_placements": [],
  };
  List<Directory> _buildingFolders = [];
  bool _isLoading = true;

  String? _mapImageName;
  File? _mapImageFile;
  List<Map<String, dynamic>> _placements = [];

  Directory? _selectedBuildingToPlace;
  Offset? _tappedRelativeCoords;

  double _imageAspectRatio = 1.0;

  // --- TAMBAHAN: Controller untuk Zoom ---
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _jsonFile = File(
      p.join(widget.districtDirectory.path, 'district_data.json'),
    );
    _loadData();
  }

  @override
  void dispose() {
    // --- TAMBAHAN: Dispose controller ---
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (await _jsonFile.exists()) {
        final content = await _jsonFile.readAsString();
        _districtData = json.decode(content);
        _mapImageName = _districtData['map_image'];
        _placements = List<Map<String, dynamic>>.from(
          _districtData['building_placements'],
        );

        if (_mapImageName != null) {
          _mapImageFile = File(
            p.join(widget.districtDirectory.path, _mapImageName!),
          );
          await _updateImageAspectRatio(_mapImageFile!);
        }
      }

      final entities = await widget.districtDirectory.list().toList();
      _buildingFolders = entities.whereType<Directory>().toList();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data peta: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

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
      print("Gagal membaca dimensi gambar: $e");
      setState(() {
        _imageAspectRatio = 1.0;
      });
    }
  }

  Future<void> _saveData() async {
    try {
      _districtData['map_image'] = _mapImageName;
      _districtData['building_placements'] = _placements;
      await _jsonFile.writeAsString(json.encode(_districtData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data peta disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
    }
  }

  Future<void> _pickDistrictMapImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      try {
        final sourceFile = File(result.files.single.path!);
        final imageName = p.basename(sourceFile.path);
        final destinationPath = p.join(
          widget.districtDirectory.path,
          imageName,
        );

        await sourceFile.copy(destinationPath);
        final newImageFile = File(destinationPath);

        await _updateImageAspectRatio(newImageFile);

        setState(() {
          _mapImageName = imageName;
          _mapImageFile = newImageFile;
        });
        await _saveData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyalin gambar: $e')));
        }
      }
    }
  }

  void _placeBuilding() {
    if (_selectedBuildingToPlace == null || _tappedRelativeCoords == null) {
      return;
    }
    final buildingName = p.basename(_selectedBuildingToPlace!.path);
    _placements.removeWhere((p) => p['building_folder_name'] == buildingName);
    _placements.add({
      'building_folder_name': buildingName,
      'map_x': _tappedRelativeCoords!.dx,
      'map_y': _tappedRelativeCoords!.dy,
    });
    setState(() {
      _selectedBuildingToPlace = null;
      _tappedRelativeCoords = null;
    });
    _saveData();
  }

  void _removePlacement(String buildingFolderName) {
    setState(() {
      _placements.removeWhere(
        (p) => p['building_folder_name'] == buildingFolderName,
      );
    });
    _saveData();
  }

  // --- TAMBAHAN: Fungsi Zoom ---
  void _zoomIn() {
    final Matrix4 matrix = _transformationController.value.clone();
    matrix.scale(1.2); // Zoom in factor
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final Matrix4 matrix = _transformationController.value.clone();
    matrix.scale(1 / 1.2); // Zoom out factor
    _transformationController.value = matrix;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
  // ------------------------------

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
      appBar: AppBar(title: const Text('Editor Peta Distrik')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildMapImageSection(),
                const Divider(height: 32),
                _buildPlacementSection(),
                const Divider(height: 32),
                _buildPlacedListSection(),
              ],
            ),
    );
  }

  Widget _buildMapImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gambar Peta', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_mapImageFile == null) const Text('Belum ada gambar peta.'),
        if (_mapImageFile != null)
          Text(
            'File: $_mapImageName',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.image),
          label: Text(
            _mapImageFile == null ? 'Pilih Gambar Peta' : 'Ganti Gambar Peta',
          ),
          onPressed: _pickDistrictMapImage,
        ),
      ],
    );
  }

  Widget _buildPlacementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tempatkan / Edit Bangunan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        DropdownButton<Directory>(
          value: _selectedBuildingToPlace,
          hint: const Text('1. Pilih bangunan... (untuk ditempatkan / diedit)'),
          isExpanded: true,
          items: _buildingFolders.map((dir) {
            return DropdownMenuItem(
              value: dir,
              child: Text(p.basename(dir.path)),
            );
          }).toList(),
          onChanged: (dir) {
            setState(() {
              _selectedBuildingToPlace = dir;
            });
          },
        ),
        const SizedBox(height: 16),
        Text(
          '2. Ketuk (tap) lokasi pada peta di bawah:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.black12,
          ),
          child:
              (_mapImageFile == null || !File(_mapImageFile!.path).existsSync())
              ? const Center(child: Text('Pilih gambar peta terlebih dahulu'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // --- PERUBAHAN: Stack untuk menumpuk tombol zoom ---
                    return Stack(
                      children: [
                        InteractiveViewer(
                          // Menggunakan controller
                          transformationController: _transformationController,
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale:
                              6.0, // Ditingkatkan agar bisa zoom lebih dalam
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: _imageAspectRatio,
                              child: LayoutBuilder(
                                builder: (context, imageConstraints) {
                                  return GestureDetector(
                                    onTapDown: (details) {
                                      final localPos = details.localPosition;
                                      setState(() {
                                        _tappedRelativeCoords = Offset(
                                          localPos.dx /
                                              imageConstraints.maxWidth,
                                          localPos.dy /
                                              imageConstraints.maxHeight,
                                        );
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        Image.file(
                                          _mapImageFile!,
                                          width: imageConstraints.maxWidth,
                                          height: imageConstraints.maxHeight,
                                          fit: BoxFit.cover,
                                        ),
                                        ..._placements.map((p) {
                                          return Positioned(
                                            left:
                                                p['map_x'] *
                                                    imageConstraints.maxWidth -
                                                15,
                                            top:
                                                p['map_y'] *
                                                    imageConstraints.maxHeight -
                                                15,
                                            child:
                                                FutureBuilder<
                                                  Map<String, dynamic>
                                                >(
                                                  future: _getBuildingIconData(
                                                    p['building_folder_name'],
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return _buildMapPinWidget(
                                                        {
                                                          'type': null,
                                                          'data': null,
                                                        },
                                                      );
                                                    }
                                                    return _buildMapPinWidget(
                                                      snapshot.data!,
                                                    );
                                                  },
                                                ),
                                          );
                                        }),
                                        if (_tappedRelativeCoords != null)
                                          Positioned(
                                            left:
                                                _tappedRelativeCoords!.dx *
                                                    imageConstraints.maxWidth -
                                                12,
                                            top:
                                                _tappedRelativeCoords!.dy *
                                                    imageConstraints.maxHeight -
                                                24,
                                            child: const Icon(
                                              Icons.add_location,
                                              color: Colors.red,
                                              size: 24,
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
                        // --- Widget Tombol Zoom ---
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                heroTag: 'reset_zoom',
                                backgroundColor: Colors.grey.shade200,
                                onPressed: _resetZoom,
                                child: const Icon(
                                  Icons.center_focus_strong,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Tempatkan / Perbarui Posisi'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed:
                (_selectedBuildingToPlace != null &&
                    _tappedRelativeCoords != null)
                ? _placeBuilding
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPlacedListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bangunan Ditempatkan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_placements.isEmpty)
          const Text('Belum ada bangunan yang ditempatkan.'),
        ..._placements.map((p) {
          final String name = p['building_folder_name'];
          final double x = p['map_x'];
          final double y = p['map_y'];

          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blue),
            title: Text(name),
            subtitle: Text(
              'Posisi: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _removePlacement(name),
              tooltip: 'Hapus dari peta',
            ),
          );
        }),
      ],
    );
  }
}
