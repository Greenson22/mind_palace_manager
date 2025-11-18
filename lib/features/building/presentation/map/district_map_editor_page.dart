// lib/features/building/presentation/map/district_map_editor_page.dart
// --- FILE BARU ---
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

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
  List<Directory> _buildingFolders = []; // Daftar bangunan di distrik ini
  bool _isLoading = true;

  // State untuk UI Editor
  String? _mapImageName;
  File? _mapImageFile;
  List<Map<String, dynamic>> _placements = [];

  Directory? _selectedBuildingToPlace;
  Offset? _tappedRelativeCoords;

  @override
  void initState() {
    super.initState();
    _jsonFile = File(
      p.join(widget.districtDirectory.path, 'district_data.json'),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Muat data JSON distrik
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
        }
      }

      // 2. Muat daftar folder bangunan
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

        // Salin gambar ke folder distrik
        await sourceFile.copy(destinationPath);

        setState(() {
          _mapImageName = imageName;
          _mapImageFile = File(destinationPath);
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

    // Cek apakah sudah ada
    _placements.removeWhere((p) => p['building_folder_name'] == buildingName);

    // Tambahkan yang baru
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

  // Mendapatkan daftar bangunan yang BELUM ditempatkan
  List<Directory> get _unplacedBuildings {
    final placedNames = _placements
        .map((p) => p['building_folder_name'])
        .toSet();
    return _buildingFolders
        .where((dir) => !placedNames.contains(p.basename(dir.path)))
        .toList();
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
          'Tempatkan Bangunan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // 1. Dropdown pilih bangunan
        DropdownButton<Directory>(
          value: _selectedBuildingToPlace,
          hint: const Text('1. Pilih bangunan untuk ditempatkan'),
          isExpanded: true,
          items: _unplacedBuildings.map((dir) {
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

        // 2. Peta Interaktif
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
                    return InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: GestureDetector(
                        // HITUNG KOORDINAT RELATIF (0.0 - 1.0)
                        onTapDown: (details) {
                          final localPos = details.localPosition;
                          setState(() {
                            _tappedRelativeCoords = Offset(
                              localPos.dx / constraints.maxWidth,
                              localPos.dy / constraints.maxHeight,
                            );
                          });
                        },
                        child: Stack(
                          children: [
                            // Gambar Peta
                            Image.file(
                              _mapImageFile!,
                              fit: BoxFit.contain,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                            ),

                            // Pin yang sudah ada
                            ..._placements.map((p) {
                              return Positioned(
                                left:
                                    p['map_x'] * constraints.maxWidth -
                                    12, // (12 = setengah lebar ikon)
                                top:
                                    p['map_y'] * constraints.maxHeight -
                                    24, // (24 = tinggi ikon)
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              );
                            }),

                            // Pin baru yang akan ditempatkan
                            if (_tappedRelativeCoords != null)
                              Positioned(
                                left:
                                    _tappedRelativeCoords!.dx *
                                        constraints.maxWidth -
                                    12,
                                top:
                                    _tappedRelativeCoords!.dy *
                                        constraints.maxHeight -
                                    24,
                                child: const Icon(
                                  Icons.add_location,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Tempatkan Bangunan'),
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
            ),
          );
        }),
      ],
    );
  }
}
