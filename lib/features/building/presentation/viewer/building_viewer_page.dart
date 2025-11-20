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

class _BuildingViewerPageState extends State<BuildingViewerPage>
    with TickerProviderStateMixin {
  late File _jsonFile;
  Map<String, dynamic> _buildingData = {'rooms': []};
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentRoom;

  // --- STATE UNTUK OBJEK & NAVIGASI ---
  bool _isObjectEditMode = false;
  List<dynamic> _roomObjects = [];
  File? _roomObjectsJsonFile;
  Directory? _roomObjectsRootDir;
  Offset? _tappedCoords;

  // --- STATE DRAG ---
  String? _movingObjectId;
  String? _draggingConnectionId;

  late bool _showIcons;
  final TransformationController _transformationController =
      TransformationController();

  // Animasi Denyut Panah
  late AnimationController _arrowPulseController;
  late Animation<double> _arrowPulseAnimation;

  List<dynamic> get _rooms => _buildingData['rooms'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.buildingDirectory.path, 'data.json'));
    _showIcons = AppSettings.defaultShowObjectIcons;

    _arrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _arrowPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _arrowPulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _arrowPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (await _jsonFile.exists()) {
        final content = await _jsonFile.readAsString();
        _buildingData = json.decode(content);

        for (var room in _rooms) {
          room['connections'] ??= [];
        }

        if (_rooms.isNotEmpty) {
          if (_currentRoom != null) {
            _currentRoom = _rooms.firstWhere(
              (r) => r['id'] == _currentRoom!['id'],
              orElse: () => _rooms[0],
            );
          } else {
            _currentRoom = _rooms[0];
          }
          await _loadRoomObjects(_currentRoom!['id']);
        } else {
          _error = 'Bangunan ini kosong.';
        }
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadRoomObjects(String roomId) async {
    _roomObjects = [];
    _movingObjectId = null;
    _draggingConnectionId = null;
    _roomObjectsRootDir = Directory(
      p.join(widget.buildingDirectory.path, 'room_objects', roomId),
    );

    if (!await _roomObjectsRootDir!.exists()) {
      await _roomObjectsRootDir!.create(recursive: true);
    }

    _roomObjectsJsonFile = File(
      p.join(_roomObjectsRootDir!.path, 'object_data.json'),
    );
    if (await _roomObjectsJsonFile!.exists()) {
      try {
        final data = json.decode(await _roomObjectsJsonFile!.readAsString());
        _roomObjects = data['children'] ?? [];
      } catch (_) {}
    } else {
      await _saveRoomObjects();
    }
  }

  Future<void> _saveRoomObjects() async {
    if (_roomObjectsJsonFile != null) {
      await _roomObjectsJsonFile!.writeAsString(
        json.encode({"view_mode": "root", "children": _roomObjects}),
      );
    }
  }

  Future<void> _saveBuildingData() async {
    await _jsonFile.writeAsString(json.encode(_buildingData));
  }

  // --- HELPER ICONS ---
  IconData _getIconForDirection(String? dir) {
    switch (dir) {
      case 'up':
        return Icons.arrow_upward;
      case 'down':
        return Icons.arrow_downward;
      case 'left':
        return Icons.arrow_back;
      case 'right':
        return Icons.arrow_forward;
      case 'up_left':
        return Icons.north_west;
      case 'up_right':
        return Icons.north_east;
      case 'down_left':
        return Icons.south_west;
      case 'down_right':
        return Icons.south_east;
      default:
        return Icons.arrow_circle_up;
    }
  }

  String _getNextDirection(String current) {
    const directions = [
      'up',
      'up_right',
      'right',
      'down_right',
      'down',
      'down_left',
      'left',
      'up_left',
    ];
    int index = directions.indexOf(current);
    if (index == -1) return 'up';
    return directions[(index + 1) % directions.length];
  }

  // --- LOGIKA DRAG & DROP & TAP ---

  // 1. Objek (Pindah Posisi)
  void _startMovingObject(String id, String name) {
    setState(() {
      _movingObjectId = id;
      _tappedCoords = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Memindahkan '$name'. Ketuk lokasi baru."),
        duration: const Duration(seconds: 2),
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
    }
  }

  // --- LOGIKA EDIT OBJEK (Dialog Baru) ---
  Future<void> _showEditObjectDialog(Map<String, dynamic> obj) async {
    final nameController = TextEditingController(text: obj['name']);
    final iconTextController = TextEditingController();

    String iconType = obj['icon_type'] ?? 'default';
    String? currentIconData = obj['icon_data'];
    String? tempNewImagePath;

    if (iconType == 'text') {
      iconTextController.text = currentIconData ?? '';
    }

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String getIconStatusText() {
              if (iconType == 'image') {
                if (tempNewImagePath != null) {
                  return 'Gambar Baru: ${p.basename(tempNewImagePath!)}';
                } else if (currentIconData != null) {
                  return 'Gambar Saat Ini: $currentIconData';
                } else {
                  return 'Belum ada gambar dipilih';
                }
              }
              return '';
            }

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
                      'Tampilan Ikon:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: iconType,
                      isExpanded: true,
                      items: ['default', 'text', 'image'].map((e) {
                        String label = 'Default';
                        if (e == 'text') label = 'Teks / Simbol';
                        if (e == 'image') label = 'Gambar / Foto';
                        return DropdownMenuItem(value: e, child: Text(label));
                      }).toList(),
                      onChanged: (v) => setDialogState(() => iconType = v!),
                    ),

                    if (iconType == 'text')
                      TextField(
                        controller: iconTextController,
                        decoration: const InputDecoration(
                          labelText: 'Karakter (Emoji/Huruf)',
                          hintText: 'Contoh: 📦',
                        ),
                        maxLength: 2,
                      ),

                    if (iconType == 'image')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
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
                                  tempNewImagePath = res.files.single.path!;
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
                    Navigator.pop(c);
                    _deleteObject(obj);
                  },
                  child: const Text('Hapus'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_with),
                  label: const Text('Pindah'),
                  onPressed: () {
                    Navigator.pop(c);
                    _startMovingObject(obj['id'], obj['name']);
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Navigator.pop(c);
                      String? finalIconData;
                      if (iconType == 'text') {
                        finalIconData = iconTextController.text;
                      } else if (iconType == 'image') {
                        finalIconData = tempNewImagePath ?? currentIconData;
                      }
                      _updateObject(
                        obj,
                        nameController.text.trim(),
                        iconType,
                        finalIconData,
                        isNewImage: tempNewImagePath != null,
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
    Map<String, dynamic> obj,
    String newName,
    String newIconType,
    String? newIconData, {
    bool isNewImage = false,
  }) async {
    if (_roomObjectsRootDir == null) return;

    // Update local state
    setState(() {
      obj['name'] = newName;
      obj['icon_type'] = newIconType;
    });

    // Handle Image File Copy
    if (newIconType == 'image' && newIconData != null && isNewImage) {
      final File checkFile = File(newIconData);
      if (checkFile.existsSync()) {
        final objectDir = Directory(
          p.join(_roomObjectsRootDir!.path, obj['id']),
        );
        if (!await objectDir.exists()) await objectDir.create();

        final ext = p.extension(newIconData);
        final fileName = 'marker_${DateTime.now().millisecondsSinceEpoch}$ext';
        final destPath = p.join(objectDir.path, fileName);

        await checkFile.copy(destPath);
        obj['icon_data'] = fileName;
      }
    } else if (newIconType == 'text') {
      obj['icon_data'] = newIconData;
    } else if (newIconType == 'default') {
      obj['icon_data'] = null;
    } else {
      // Keep existing image filename
      obj['icon_data'] = newIconData;
    }

    await _saveRoomObjects();
  }

  Future<void> _deleteObject(Map<String, dynamic> obj) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Objek?'),
        content: Text('Hapus "${obj['name']}"?'),
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
      if (_roomObjectsRootDir != null) {
        final objectDir = Directory(
          p.join(_roomObjectsRootDir!.path, obj['id']),
        );
        if (await objectDir.exists()) {
          await objectDir.delete(recursive: true);
        }
      }
      setState(() {
        _roomObjects.removeWhere((item) => item['id'] == obj['id']);
      });
      await _saveRoomObjects();
    }
  }

  // --- FUNGSI NAVIGASI REKURSIF ---
  void _openObject(Map<String, dynamic> obj) {
    if (_roomObjectsRootDir == null) return;

    final objectId = obj['id'];
    final objectDir = Directory(p.join(_roomObjectsRootDir!.path, objectId));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecursiveObjectPage(
          objectDirectory: objectDir,
          objectName: obj['name'] ?? 'Objek',
        ),
      ),
    ).then((_) {
      // Refresh saat kembali
      if (_currentRoom != null) {
        _loadRoomObjects(_currentRoom!['id']);
      }
    });
  }

  // 2. Navigasi
  Future<void> _updateConnectionPosition(
    String connId,
    double x,
    double y,
  ) async {
    if (_currentRoom == null) return;
    final connections = _currentRoom!['connections'] as List;
    final index = connections.indexWhere((c) => c['id'] == connId);
    if (index != -1) {
      connections[index]['x'] = x;
      connections[index]['y'] = y;
      await _saveBuildingData();
    }
  }

  Future<void> _cycleConnectionDirection(String connId) async {
    if (_currentRoom == null) return;
    final connections = _currentRoom!['connections'] as List;
    final index = connections.indexWhere((c) => c['id'] == connId);
    if (index != -1) {
      final currentDir = connections[index]['direction'] ?? 'up';
      final nextDir = _getNextDirection(currentDir);
      setState(() {
        connections[index]['direction'] = nextDir;
      });
      await _saveBuildingData();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Arah: $nextDir"),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  // --- DIALOGS ---
  Future<void> _showAddObjectDialog() async {
    if (_tappedCoords == null) return;
    final nameController = TextEditingController();
    String selectedType = 'mapContainer';
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Objek'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
                autofocus: true,
              ),
              RadioListTile(
                title: const Text('Wadah'),
                value: 'mapContainer',
                groupValue: selectedType,
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              RadioListTile(
                title: const Text('Lokasi'),
                value: 'immersiveView',
                groupValue: selectedType,
                onChanged: (v) => setState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _createNewObject(nameController.text, selectedType);
                  Navigator.pop(c);
                }
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewObject(String name, String viewMode) async {
    final id = 'obj_${DateTime.now().millisecondsSinceEpoch}';
    final dir = Directory(p.join(_roomObjectsRootDir!.path, id));
    await dir.create();
    await File(
      p.join(dir.path, 'object_data.json'),
    ).writeAsString(json.encode({"view_mode": viewMode, "children": []}));

    setState(() {
      _roomObjects.add({
        "id": id,
        "name": name,
        "x": _tappedCoords!.dx,
        "y": _tappedCoords!.dy,
        "type": viewMode,
        "icon_type": "default",
        "icon_data": null,
      });
      _tappedCoords = null;
    });
    await _saveRoomObjects();
  }

  void _toggleEditMode() {
    setState(() {
      _isObjectEditMode = !_isObjectEditMode;
      _tappedCoords = null;
      _movingObjectId = null;
      _draggingConnectionId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isObjectEditMode
              ? 'Mode Edit Aktif: Ketuk Objek untuk Edit'
              : 'Mode Lihat',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToRoom(String id) async {
    try {
      final target = _rooms.firstWhere((r) => r['id'] == id);
      setState(() {
        _currentRoom = target;
        _isObjectEditMode = false;
        _tappedCoords = null;
      });
      await _loadRoomObjects(id);
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ruangan tidak ditemukan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoom?['name'] ?? 'Viewer'),
        actions: [
          if (_isObjectEditMode && _movingObjectId != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Batal Pindah',
              onPressed: () => setState(() => _movingObjectId = null),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _toggleEditMode();
              if (v == 'icons') setState(() => _showIcons = !_showIcons);
              if (v == 'structure')
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => RoomEditorPage(
                      buildingDirectory: widget.buildingDirectory,
                    ),
                  ),
                ).then((_) => _loadData());
            },
            itemBuilder: (c) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  _isObjectEditMode
                      ? 'Selesai Edit'
                      : 'Mode Edit (Objek & Navigasi)',
                ),
              ),
              PopupMenuItem(
                value: 'icons',
                child: Text(
                  _showIcons ? 'Sembunyikan Objek' : 'Tampilkan Objek',
                ),
              ),
              const PopupMenuItem(
                value: 'structure',
                child: Text('Edit Struktur Ruangan'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRoomContent(),
    );
  }

  Widget _buildRoomContent() {
    if (_currentRoom == null) return const Center(child: Text('Error Data'));
    final imagePath = _currentRoom!['image'];
    final connections = _currentRoom!['connections'] as List? ?? [];

    Widget bgImage = imagePath != null
        ? Image.file(
            File(p.join(widget.buildingDirectory.path, imagePath)),
            fit: BoxFit.contain,
          )
        : const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 100,
              color: Colors.grey,
            ),
          );

    double objOpacity = _isObjectEditMode
        ? 1.0
        : (_showIcons ? AppSettings.objectIconOpacity : 0.0);
    bool objInteractive =
        _isObjectEditMode || _showIcons || AppSettings.interactableWhenHidden;

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 5.0,
          child: Center(
            child: Stack(
              children: [
                // 1. Layer Gambar & Tap Area
                GestureDetector(
                  onTapDown: _isObjectEditMode
                      ? (d) {
                          final x = d.localPosition.dx / constraints.maxWidth;
                          final y = d.localPosition.dy / constraints.maxHeight;
                          if (_movingObjectId != null) {
                            _confirmMoveObject(x, y);
                          } else if (_draggingConnectionId == null) {
                            setState(() => _tappedCoords = Offset(x, y));
                            _showAddObjectDialog();
                          }
                        }
                      : null,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: bgImage,
                  ),
                ),

                // 2. Layer Objek (Furniture)
                ..._roomObjects.map((obj) {
                  final double x = obj['x'] ?? 0.5;
                  final double y = obj['y'] ?? 0.5;
                  final bool isMoving = obj['id'] == _movingObjectId;

                  return Positioned(
                    left: x * constraints.maxWidth - 20,
                    top: y * constraints.maxHeight - 20,
                    child: IgnorePointer(
                      ignoring: !objInteractive,
                      child: Opacity(
                        opacity: objOpacity,
                        child: _buildObjectWidget(obj, isMoving),
                      ),
                    ),
                  );
                }),

                // 3. Layer Navigasi (Panah)
                if (AppSettings.showNavigationArrows)
                  ...connections.map((conn) {
                    final String direction = conn['direction'] ?? 'up';
                    final String label = conn['label'] ?? 'Pintu';
                    final String connId = conn['id'];

                    double x = conn['x'] ?? 0.5;
                    double y = conn['y'] ?? 0.5;
                    if (conn['x'] == null) {
                      x = 0.5;
                      y = 0.5;
                    }

                    final double sizeBase =
                        24 * AppSettings.navigationArrowScale;

                    return Positioned(
                      left: x * constraints.maxWidth - sizeBase,
                      top: y * constraints.maxHeight - sizeBase,
                      child: GestureDetector(
                        onPanUpdate: _isObjectEditMode
                            ? (d) {
                                setState(() {
                                  double nx =
                                      x + (d.delta.dx / constraints.maxWidth);
                                  double ny =
                                      y + (d.delta.dy / constraints.maxHeight);
                                  conn['x'] = nx.clamp(0.0, 1.0);
                                  conn['y'] = ny.clamp(0.0, 1.0);
                                  _draggingConnectionId = connId;
                                });
                              }
                            : null,
                        onPanEnd: _isObjectEditMode
                            ? (d) {
                                _updateConnectionPosition(
                                  connId,
                                  conn['x'],
                                  conn['y'],
                                );
                                setState(() => _draggingConnectionId = null);
                              }
                            : null,
                        onTap: () {
                          if (_isObjectEditMode) {
                            _cycleConnectionDirection(connId);
                          } else {
                            _navigateToRoom(conn['targetRoomId']);
                          }
                        },
                        child: ScaleTransition(
                          scale: _isObjectEditMode
                              ? const AlwaysStoppedAnimation(1.0)
                              : _arrowPulseAnimation,
                          child: _buildArrowWidget(
                            label,
                            direction,
                            _draggingConnectionId == connId,
                          ),
                        ),
                      ),
                    );
                  }),

                if (_tappedCoords != null)
                  Positioned(
                    left: _tappedCoords!.dx * constraints.maxWidth - 15,
                    top: _tappedCoords!.dy * constraints.maxHeight - 30,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildObjectWidget(Map<String, dynamic> obj, bool isMoving) {
    final iconType = obj['icon_type'] ?? 'default';
    final iconData = obj['icon_data'];

    Widget content;

    if (iconType == 'image' &&
        iconData != null &&
        _roomObjectsRootDir != null) {
      final file = File(p.join(_roomObjectsRootDir!.path, obj['id'], iconData));
      if (file.existsSync()) {
        content = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMoving ? Colors.greenAccent : Colors.white,
              width: isMoving ? 3 : 2,
            ),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
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
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                )
              : null,
        );
      } else {
        content = _buildDefaultObjectIcon(obj, isMoving);
      }
    } else if (iconType == 'text' && iconData != null) {
      content = Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isMoving ? Colors.green : Colors.blue.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isMoving ? Colors.greenAccent : Colors.white,
            width: isMoving ? 3 : 2,
          ),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              iconData,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            if (_isObjectEditMode && !isMoving)
              const Icon(Icons.edit, color: Colors.white70, size: 14),
          ],
        ),
      );
    } else {
      content = _buildDefaultObjectIcon(obj, isMoving);
    }

    // Wrapper GestureDetector untuk logika Tap
    return GestureDetector(
      onTap: () {
        if (_isObjectEditMode) {
          // Jika sedang mode edit, buka dialog edit
          // (Kecuali sedang memindahkan objek ini sendiri, tapi logic drag diurus parent)
          if (!isMoving) _showEditObjectDialog(obj);
        } else {
          // Mode lihat: buka objek
          _openObject(obj);
        }
      },
      child: content,
    );
  }

  Widget _buildDefaultObjectIcon(Map<String, dynamic> obj, bool isMoving) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isMoving ? Colors.green : Colors.blue.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        _isObjectEditMode && !isMoving ? Icons.edit : Icons.inbox,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildArrowWidget(String label, String direction, bool isDragging) {
    final double scale = AppSettings.navigationArrowScale;
    final Color color = Color(AppSettings.navigationArrowColor);
    final double opacity = AppSettings.navigationArrowOpacity;

    return Opacity(
      opacity: isDragging ? 1.0 : opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10 * scale,
                ),
              ],
            ),
            child: Icon(
              _getIconForDirection(direction),
              size: 48 * scale,
              color: isDragging ? Colors.yellow : color,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
          if (_isObjectEditMode || AppSettings.showRegionDistrictNames)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: isDragging ? Border.all(color: Colors.yellow) : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isDragging ? Colors.yellow : color,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
