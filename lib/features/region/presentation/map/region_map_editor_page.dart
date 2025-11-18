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
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.regionDirectory.path, 'region_data.json'));
    _loadData();
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
        _updateImageAspectRatio(_mapImageFile!);
      }
    }
    final entities = await widget.regionDirectory.list().toList();
    _districtFolders = entities.whereType<Directory>().toList();
    setState(() {});
  }

  Future<void> _updateImageAspectRatio(File imageFile) async {
    final data = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    setState(() => _imageAspectRatio = frame.image.width / frame.image.height);
  }

  Future<void> _saveData() async {
    _regionData['map_image'] = _mapImageName;
    _regionData['district_placements'] = _placements;
    await _jsonFile.writeAsString(json.encode(_regionData));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Disimpan!')));
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
    if (_selectedDistrictToPlace == null || _tappedRelativeCoords == null)
      return;
    final name = p.basename(_selectedDistrictToPlace!.path);
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

  // UI Build mirip DistrictMapEditorPage tapi untuk Region
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor Peta Wilayah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _pickMapImage,
            child: Text(_mapImageFile == null ? 'Pilih Peta' : 'Ganti Peta'),
          ),
          const SizedBox(height: 16),
          DropdownButton<Directory>(
            value: _selectedDistrictToPlace,
            hint: const Text('Pilih Distrik untuk ditempatkan'),
            isExpanded: true,
            items: _districtFolders
                .map(
                  (d) => DropdownMenuItem(
                    value: d,
                    child: Text(p.basename(d.path)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedDistrictToPlace = v),
          ),
          const SizedBox(height: 8),
          Container(
            height: 400,
            color: Colors.black12,
            child: _mapImageFile == null
                ? const Center(child: Text('Belum ada gambar peta'))
                : InteractiveViewer(
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
                                  ..._placements.map(
                                    (pl) => Positioned(
                                      left: pl['map_x'] * cons.maxWidth - 15,
                                      top: pl['map_y'] * cons.maxHeight - 15,
                                      child: const Icon(
                                        Icons.holiday_village,
                                        color: Colors.blue,
                                        size: 30,
                                      ), // Simple icon
                                    ),
                                  ),
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
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _placeDistrict,
            child: const Text('Tempatkan Distrik'),
          ),
        ],
      ),
    );
  }
}
