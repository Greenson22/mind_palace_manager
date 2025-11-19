// lib/features/building/presentation/viewer/building_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
import 'package:mind_palace_manager/features/objects/presentation/recursive_object_page.dart';

class BuildingViewerPage extends StatefulWidget {
  final Directory buildingDirectory;

  const BuildingViewerPage({super.key, required this.buildingDirectory});

  @override
  State<BuildingViewerPage> createState() => _BuildingViewerPageState();
}

class _BuildingViewerPageState extends State<BuildingViewerPage> {
  late File _jsonFile;
  Map<String, dynamic> _buildingData = {'rooms': []};
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentRoom;

  // --- STATE UNTUK OBJEK DALAM RUANGAN ---
  bool _isObjectEditMode = false;
  List<dynamic> _roomObjects = [];
  File? _roomObjectsJsonFile;
  Directory? _roomObjectsRootDir;
  Offset? _tappedCoords;

  // --- STATE PINDAH POSISI ---
  String? _movingObjectId;

  late bool _showIcons;
  final TransformationController _transformationController =
      TransformationController();

  List<dynamic> get _rooms => _buildingData['rooms'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.buildingDirectory.path, 'data.json'));
    _showIcons = AppSettings.defaultShowObjectIcons;
    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!await _jsonFile.exists()) {
        throw Exception('File data.json tidak ditemukan.');
      }
      final content = await _jsonFile.readAsString();
      _buildingData = json.decode(content);

      for (var room in _rooms) {
        room['connections'] ??= [];
      }

      if (_rooms.isNotEmpty) {
        if (_currentRoom != null) {
          final found = _rooms.firstWhere(
            (r) => r['id'] == _currentRoom!['id'],
            orElse: () => null,
          );
          _currentRoom = found ?? _rooms[0];
        } else {
          _currentRoom = _rooms[0];
        }
        await _loadRoomObjects(_currentRoom!['id']);
      } else {
        _error = 'Bangunan ini belum memiliki ruangan.';
      }
    } catch (e) {
      _error = 'Gagal memuat data: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRoomObjects(String roomId) async {
    _roomObjects = [];
    _movingObjectId = null;
    _roomObjectsRootDir = Directory(
      p.join(widget.buildingDirectory.path, 'room_objects', roomId.toString()),
    );

    if (!await _roomObjectsRootDir!.exists()) {
      await _roomObjectsRootDir!.create(recursive: true);
    }

    _roomObjectsJsonFile = File(
      p.join(_roomObjectsRootDir!.path, 'object_data.json'),
    );

    if (await _roomObjectsJsonFile!.exists()) {
      try {
        final content = await _roomObjectsJsonFile!.readAsString();
        final data = json.decode(content);
        _roomObjects = data['children'] ?? [];
      } catch (e) {
        print("Error parsing room objects: $e");
      }
    } else {
      await _saveRoomObjects();
    }
  }

  Future<void> _saveRoomObjects() async {
    if (_roomObjectsJsonFile == null) return;
    final data = {"view_mode": "root", "children": _roomObjects};
    await _roomObjectsJsonFile!.writeAsString(json.encode(data));
  }

  // --- LOGIKA PINDAH POSISI ---
  void _startMovingObject(String id, String name) {
    setState(() {
      _movingObjectId = id;
      _tappedCoords = null;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Memindahkan '$name'. Ketuk lokasi baru."),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _confirmMoveObject(double x, double y) async {
    if (_movingObjectId == null) return;

    final index = _roomObjects.indexWhere(
      (obj) => obj['id'] == _movingObjectId,
    );
    if (index != -1) {
      setState(() {
        _roomObjects[index]['x'] = x;
        _roomObjects[index]['y'] = y;
        _movingObjectId = null;
      });
      await _saveRoomObjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Posisi berhasil diperbarui.")),
        );
      }
    }
  }

  void _cancelMove() {
    setState(() {
      _movingObjectId = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Batal memindahkan.")));
  }

  Future<void> _showAddObjectDialog() async {
    if (_tappedCoords == null) return;
    final nameController = TextEditingController();
    String selectedType = 'mapContainer';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Objek'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Objek',
                      hintText: 'Contoh: Lemari, Laci',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Tipe Perilaku:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Wadah (Container)'),
                    subtitle: const Text('Seperti Distrik.'),
                    value: 'mapContainer',
                    groupValue: selectedType,
                    onChanged: (val) =>
                        setDialogState(() => selectedType = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Lokasi (Immersive)'),
                    subtitle: const Text('Seperti Ruangan.'),
                    value: 'immersiveView',
                    groupValue: selectedType,
                    onChanged: (val) =>
                        setDialogState(() => selectedType = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      _createNewObject(
                        nameController.text.trim(),
                        selectedType,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Buat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewObject(String name, String viewMode) async {
    if (_roomObjectsRootDir == null || _tappedCoords == null) return;

    final folderId = 'obj_${DateTime.now().millisecondsSinceEpoch}';
    final childDir = Directory(p.join(_roomObjectsRootDir!.path, folderId));
    await childDir.create();

    final childJsonFile = File(p.join(childDir.path, 'object_data.json'));
    await childJsonFile.writeAsString(
      json.encode({"view_mode": viewMode, "image_path": null, "children": []}),
    );

    final newObject = {
      "id": folderId,
      "name": name,
      "x": _tappedCoords!.dx,
      "y": _tappedCoords!.dy,
      "type": viewMode,
      "icon_type": "default",
      "icon_path": null,
    };

    setState(() {
      _roomObjects.add(newObject);
      _tappedCoords = null;
    });
    await _saveRoomObjects();
  }

  Future<void> _showEditObjectDialog(Map<String, dynamic> obj) async {
    final nameController = TextEditingController(text: obj['name']);
    String selectedType = obj['type'] ?? 'mapContainer';
    String iconType = obj['icon_type'] ?? 'default';
    String? tempIconPath = obj['icon_path'];

    String getIconStatusText() {
      if (iconType == 'image' && tempIconPath != null) {
        return 'Gambar terpilih: ${p.basename(tempIconPath!)}';
      }
      return 'Menggunakan Ikon Standar';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit: ${obj['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Objek',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tipe Perilaku:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'mapContainer',
                          child: Text('Wadah (Container)'),
                        ),
                        DropdownMenuItem(
                          value: 'immersiveView',
                          child: Text('Lokasi (Immersive)'),
                        ),
                      ],
                      onChanged: (val) =>
                          setDialogState(() => selectedType = val!),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tampilan Ikon:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'default',
                          groupValue: iconType,
                          onChanged: (v) => setDialogState(() => iconType = v!),
                        ),
                        const Text('Default'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'image',
                          groupValue: iconType,
                          onChanged: (v) => setDialogState(() => iconType = v!),
                        ),
                        const Text('Foto Custom'),
                      ],
                    ),
                    if (iconType == 'image')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Pilih Foto Marker'),
                            onPressed: () async {
                              final res = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );
                              if (res != null &&
                                  res.files.single.path != null) {
                                setDialogState(() {
                                  tempIconPath = res.files.single.path!;
                                });
                              }
                            },
                          ),
                          Text(
                            getIconStatusText(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteObject(obj);
                  },
                  child: const Text('Hapus'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_with),
                  label: const Text('Pindah'),
                  onPressed: () {
                    Navigator.pop(context);
                    _startMovingObject(obj['id'], obj['name']);
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      await _updateObject(
                        obj,
                        nameController.text.trim(),
                        selectedType,
                        iconType,
                        tempIconPath,
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateObject(
    Map<String, dynamic> originalObj,
    String newName,
    String newType,
    String newIconType,
    String? newIconPath,
  ) async {
    setState(() {
      originalObj['name'] = newName;
      originalObj['type'] = newType;
      originalObj['icon_type'] = newIconType;
    });

    if (newIconType == 'image' && newIconPath != null) {
      final File checkFile = File(newIconPath);
      if (checkFile.isAbsolute && await checkFile.exists()) {
        final objectDir = Directory(
          p.join(_roomObjectsRootDir!.path, originalObj['id']),
        );
        if (!await objectDir.exists()) await objectDir.create();

        final ext = p.extension(newIconPath);
        final fileName =
            'marker_icon${DateTime.now().millisecondsSinceEpoch}$ext';
        final destPath = p.join(objectDir.path, fileName);

        await checkFile.copy(destPath);
        originalObj['icon_path'] = fileName;
      } else {
        originalObj['icon_path'] = newIconPath;
      }
    } else {
      originalObj['icon_path'] = null;
    }

    await _saveRoomObjects();

    try {
      final childJsonFile = File(
        p.join(
          _roomObjectsRootDir!.path,
          originalObj['id'],
          'object_data.json',
        ),
      );
      if (await childJsonFile.exists()) {
        final content = await childJsonFile.readAsString();
        final data = json.decode(content);
        data['view_mode'] = newType;
        await childJsonFile.writeAsString(json.encode(data));
      }
    } catch (e) {
      print("Gagal update config anak: $e");
    }
    setState(() {});
  }

  Future<void> _deleteObject(Map<String, dynamic> obj) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Objek?'),
        content: Text(
          'Objek "${obj['name']}" dan seluruh isinya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final childDir = Directory(p.join(_roomObjectsRootDir!.path, obj['id']));
      if (await childDir.exists()) {
        await childDir.delete(recursive: true);
      }
      setState(() {
        _roomObjects.removeWhere((e) => e['id'] == obj['id']);
        if (_movingObjectId == obj['id']) _movingObjectId = null;
      });
      await _saveRoomObjects();
    }
  }

  void _navigateToRoom(String targetRoomId) async {
    try {
      final targetRoom = _rooms.firstWhere((r) => r['id'] == targetRoomId);
      setState(() {
        _currentRoom = targetRoom;
        _isObjectEditMode = false;
        _tappedCoords = null;
        _movingObjectId = null;
      });

      // --- LOAD OBJECTS ---
      await _loadRoomObjects(targetRoomId);

      // --- PERBAIKAN: Refresh UI setelah objek dimuat ---
      if (mounted) {
        setState(() {});
      }
      // --------------------------------------------------
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruangan tujuan tidak ditemukan!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleObjectTap(Map<String, dynamic> obj) {
    if (_isObjectEditMode) {
      if (_movingObjectId != null) return;
      _showEditObjectDialog(obj);
    } else {
      _enterObject(obj);
    }
  }

  void _enterObject(Map<String, dynamic> obj) {
    final childDir = Directory(p.join(_roomObjectsRootDir!.path, obj['id']));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecursiveObjectPage(
          objectDirectory: childDir,
          objectName: obj['name'],
        ),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToRoomEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RoomEditorPage(buildingDirectory: widget.buildingDirectory),
      ),
    ).then((_) => _loadData());
  }

  void _toggleObjectEditMode() {
    setState(() {
      _isObjectEditMode = !_isObjectEditMode;
      _tappedCoords = null;
      _movingObjectId = null;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isObjectEditMode
              ? 'Mode Edit: Ketuk objek untuk mengedit.'
              : 'Mode Lihat Aktif',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(p.basename(widget.buildingDirectory.path)),
            if (_currentRoom != null)
              Text(
                _currentRoom!['name'] ?? 'Ruangan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
          ],
        ),
        actions: [
          if (_isObjectEditMode && _movingObjectId != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Batal Pindah',
              onPressed: _cancelMove,
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'toggle_edit_mode') {
                _toggleObjectEditMode();
              } else if (v == 'toggle_icons') {
                setState(() {
                  _showIcons = !_showIcons;
                });
              } else if (v == 'edit_room_structure') {
                _navigateToRoomEditor();
              }
            },
            itemBuilder: (c) => [
              PopupMenuItem(
                value: 'toggle_edit_mode',
                child: Row(
                  children: [
                    Icon(
                      _isObjectEditMode
                          ? Icons.check_circle
                          : Icons.edit_attributes,
                      color: _isObjectEditMode ? Colors.green : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isObjectEditMode
                          ? 'Selesai Edit Objek'
                          : 'Mode Edit Objek',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_icons',
                child: Row(
                  children: [
                    Icon(
                      _showIcons ? Icons.visibility : Icons.visibility_off,
                      color: _showIcons ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(_showIcons ? 'Sembunyikan Ikon' : 'Tampilkan Ikon'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_room_structure',
                child: Row(
                  children: [
                    Icon(Icons.construction),
                    SizedBox(width: 8),
                    Text('Edit Struktur Ruangan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    if (_currentRoom == null)
      return const Center(child: Text('Tidak ada ruangan.'));

    return _buildRoomViewer(_currentRoom!);
  }

  Widget _buildRoomViewer(Map<String, dynamic> room) {
    final roomImage = room['image'];
    final connections = (room['connections'] as List? ?? []);

    Widget imageWidget;
    if (roomImage != null) {
      final imageFile = File(p.join(widget.buildingDirectory.path, roomImage));
      imageWidget = Image.file(
        imageFile,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.image_not_supported, size: 100)),
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.sensor_door, size: 100, color: Colors.grey),
      );
    }

    double finalOpacity;
    if (_isObjectEditMode) {
      finalOpacity = 1.0;
    } else {
      finalOpacity = _showIcons ? AppSettings.objectIconOpacity : 0.0;
    }

    bool isInteractable;
    if (_isObjectEditMode) {
      isInteractable = true;
    } else {
      isInteractable = _showIcons ? true : AppSettings.interactableWhenHidden;
    }

    return Column(
      children: [
        if (_isObjectEditMode && _movingObjectId != null)
          Container(
            color: Colors.blue.shade100,
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            child: const Text(
              "MODE PINDAH AKTIF: Ketuk lokasi baru untuk meletakkan ikon.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: Container(
            color: Colors.black12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            if (_isObjectEditMode) {
                              final x =
                                  details.localPosition.dx /
                                  constraints.maxWidth;
                              final y =
                                  details.localPosition.dy /
                                  constraints.maxHeight;

                              if (_movingObjectId != null) {
                                _confirmMoveObject(x, y);
                              } else {
                                setState(() {
                                  _tappedCoords = Offset(x, y);
                                });
                                _showAddObjectDialog();
                              }
                            }
                          },
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: imageWidget,
                          ),
                        ),

                        ..._roomObjects.map((obj) {
                          final double x = obj['x'] ?? 0.5;
                          final double y = obj['y'] ?? 0.5;
                          final String type = obj['type'] ?? 'mapContainer';
                          final String name = obj['name'] ?? 'Objek';
                          final String iconType = obj['icon_type'] ?? 'default';
                          final String? iconPath = obj['icon_path'];
                          final bool isMoving = (obj['id'] == _movingObjectId);

                          final IconData defaultIconData =
                              type == 'mapContainer'
                              ? Icons.inbox
                              : Icons.touch_app;
                          final Color defaultColor = type == 'mapContainer'
                              ? Colors.blue
                              : Colors.orange;

                          Widget markerWidget;

                          if (iconType == 'image' && iconPath != null) {
                            final file = File(
                              p.join(
                                _roomObjectsRootDir!.path,
                                obj['id'],
                                iconPath,
                              ),
                            );
                            if (file.existsSync()) {
                              markerWidget = Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isMoving
                                        ? Colors.greenAccent
                                        : Colors.white,
                                    width: isMoving ? 3 : 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: FileImage(file),
                                    fit: BoxFit.cover,
                                    opacity: isMoving ? 0.5 : 1.0,
                                  ),
                                ),
                                child: _isObjectEditMode && !isMoving
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      )
                                    : null,
                              );
                            } else {
                              markerWidget = _buildDefaultMarker(
                                defaultIconData,
                                defaultColor,
                                isMoving,
                              );
                            }
                          } else {
                            markerWidget = _buildDefaultMarker(
                              defaultIconData,
                              defaultColor,
                              isMoving,
                            );
                          }

                          Widget finalMarker = GestureDetector(
                            onTap: () => _handleObjectTap(obj),
                            child: Tooltip(
                              message: name,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  markerWidget,
                                  if (_isObjectEditMode ||
                                      (_showIcons &&
                                          AppSettings.showRegionDistrictNames))
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMoving
                                            ? Colors.green
                                            : Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isMoving ? 'Pindahkan...' : name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );

                          return Positioned(
                            left: x * constraints.maxWidth - 20,
                            top: y * constraints.maxHeight - 20,
                            child: IgnorePointer(
                              ignoring: !isInteractable,
                              child: Opacity(
                                opacity: finalOpacity,
                                child: finalMarker,
                              ),
                            ),
                          );
                        }).toList(),

                        if (_isObjectEditMode &&
                            _tappedCoords != null &&
                            _movingObjectId == null)
                          Positioned(
                            left: _tappedCoords!.dx * constraints.maxWidth - 15,
                            top: _tappedCoords!.dy * constraints.maxHeight - 30,
                            child: const Icon(
                              Icons.add_location_alt,
                              color: Colors.redAccent,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Navigasi Pintu:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (connections.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Tidak ada pintu lain dari sini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  children: connections.map<Widget>((conn) {
                    return ActionChip(
                      avatar: const Icon(Icons.door_front_door, size: 16),
                      label: Text(conn['label'] ?? 'Pindah'),
                      onPressed: () => _navigateToRoom(conn['targetRoomId']),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultMarker(IconData icon, Color color, bool isMoving) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isMoving ? Colors.green : color.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(
          color: isMoving ? Colors.greenAccent : Colors.white,
          width: isMoving ? 3 : 2,
        ),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Icon(
        _isObjectEditMode && !isMoving ? Icons.edit : icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
