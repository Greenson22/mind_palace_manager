// lib/features/region/presentation/map/region_map_editor_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

// --- IMPORT DIALOG AI (Pastikan file ini sudah dibuat di langkah sebelumnya) ---
// Kita menggunakan dialog yang sama karena strukturnya mirip.
import 'package:mind_palace_manager/features/world/presentation/dialogs/ai_map_prompt_dialog.dart';

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

  // Controller untuk Zoom Manual
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

  // --- LOGIKA DATA ---

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
    _regionData['map_image'] = _mapImageName;
    _regionData['district_placements'] = _placements;
    await _jsonFile.writeAsString(json.encode(_regionData));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan wilayah disimpan!')),
      );
    }
  }

  // --- LOGIKA GAMBAR & AI ---

  Future<void> _pickMapImage() async {
    var res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null) {
      final src = File(res.files.single.path!);
      final extension = p.extension(src.path);

      // Gunakan nama file tetap untuk wilayah ini
      const baseName = 'region_map';
      final newFixedFileName = '$baseName$extension';

      final String? oldMapImageName = _mapImageName;

      // 1. Copy file baru
      final destPath = p.join(widget.regionDirectory.path, newFixedFileName);
      await src.copy(destPath);

      // 2. Hapus file lama jika namanya berbeda (misal beda ekstensi)
      if (oldMapImageName != null && oldMapImageName != newFixedFileName) {
        try {
          final oldFile = File(
            p.join(widget.regionDirectory.path, oldMapImageName),
          );
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          print("Failed to delete old region map image: $e");
        }
      }

      // 3. Update state variables
      _mapImageName = newFixedFileName;
      _mapImageFile = File(destPath);
      await _updateImageAspectRatio(_mapImageFile!);

      // 4. Save data
      _saveData();
      setState(() {});
    }
  }

  // Fungsi Memunculkan Dialog AI
  void _showAiPromptDialog() {
    showDialog(
      context: context,
      builder: (context) => const AiMapPromptDialog(),
    );
  }

  // --- LOGIKA PENEMPATAN DISTRIK ---

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

  // --- FUNGSI ZOOM ---
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

  // --- HELPER: AMBIL IKON DISTRIK ---
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

  // --- WIDGET PIN ---
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

  // --- UI UTAMA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Peta Wilayah'),
        actions: [
          // --- TOMBOL AI DI APPBAR ---
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
            tooltip: "AI Prompt Generator",
            onPressed: _showAiPromptDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- BAGIAN GAMBAR & AI ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gambar Peta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // Tombol Text Alternatif
              TextButton.icon(
                icon: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.purple,
                ),
                label: const Text(
                  "Buat Prompt AI",
                  style: TextStyle(color: Colors.purple),
                ),
                onPressed: _showAiPromptDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Info Gambar
          if (_mapImageFile == null)
            const Text('Belum ada gambar peta.')
          else
            Text(
              'File: $_mapImageName',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),

          const SizedBox(height: 8),

          // Tombol Pilih Gambar
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            onPressed: _pickMapImage,
            label: Text(
              _mapImageFile == null ? 'Pilih Peta dari Galeri' : 'Ganti Peta',
            ),
          ),

          const Divider(height: 32),

          // --- BAGIAN PENEMPATAN DISTRIK ---
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

          // CANVAS INTERAKTIF
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
                                      // Render Pin Distrik
                                      ..._placements.map((pl) {
                                        final name = pl['district_folder_name'];
                                        return Positioned(
                                          left:
                                              pl['map_x'] * cons.maxWidth - 20,
                                          top:
                                              pl['map_y'] * cons.maxHeight - 20,
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
                                      // Indikator Tap Posisi Baru
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
                      // Tombol Zoom
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

          // Daftar Distrik Terpasang
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
