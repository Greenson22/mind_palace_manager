// lib/features/building/presentation/viewer/building_viewer_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math; // Import math untuk PI
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
import 'package:mind_palace_manager/features/objects/presentation/recursive_object_page.dart';

class BuildingViewerPage extends StatefulWidget {
  final Directory buildingDirectory;
  final String? initialRoomId;

  const BuildingViewerPage({
    super.key,
    required this.buildingDirectory,
    this.initialRoomId,
  });

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

  // --- EXPORT KEY ---
  final GlobalKey _globalKey = GlobalKey();

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
            if (widget.initialRoomId != null) {
              _currentRoom = _rooms.firstWhere(
                (r) => r['id'] == widget.initialRoomId,
                orElse: () => _rooms[0],
              );
            } else {
              _currentRoom = _rooms[0];
            }
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

  double _getRotation(Map<String, dynamic> conn) {
    if (conn['rotation'] != null) {
      return (conn['rotation'] as num).toDouble();
    }
    String dir = conn['direction'] ?? 'up';
    switch (dir) {
      case 'up':
        return 0.0;
      case 'up_right':
        return math.pi / 4;
      case 'right':
        return math.pi / 2;
      case 'down_right':
        return 3 * math.pi / 4;
      case 'down':
        return math.pi;
      case 'down_left':
        return 5 * math.pi / 4;
      case 'left':
        return 3 * math.pi / 2;
      case 'up_left':
        return 7 * math.pi / 4;
      default:
        return 0.0;
    }
  }

  // --- MODIFIED DIALOG: HAPUS TANDA X & KONFIRMASI ---
  Future<void> _showRotationDialog(Map<String, dynamic> conn) async {
    double currentRotation = _getRotation(conn);

    // Sudut default
    final List<Map<String, dynamic>> defaultPresets = [
      {"label": "Atas", "deg": 0},
      {"label": "Kanan", "deg": 90},
      {"label": "Bawah", "deg": 180},
      {"label": "Kiri", "deg": 270},
      {"label": "45°", "deg": 45},
      {"label": "135°", "deg": 135},
      {"label": "225°", "deg": 225},
      {"label": "315°", "deg": 315},
    ];

    // Load preset user dari settings
    List<Map<String, dynamic>> userPresets = List.from(
      AppSettings.customRotationPresets,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Helper: Tambah Preset Baru
            Future<void> _addNewPreset() async {
              String newName = "";
              final currentDeg =
                  (currentRotation * 180 / math.pi).round() % 360;

              await showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text("Simpan Sudut Ini"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Nilai: $currentDeg°",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: "Nama Sudut",
                          hintText: "Contoh: Lorong Miring",
                        ),
                        onChanged: (v) => newName = v,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (newName.trim().isNotEmpty) {
                          final newPreset = {
                            "name": newName.trim(),
                            "value": currentRotation,
                          };
                          final updatedList = [
                            ...AppSettings.customRotationPresets,
                            newPreset,
                          ];

                          AppSettings.saveCustomRotationPresets(updatedList);
                          setDialogState(() {
                            userPresets = updatedList;
                          });
                          Navigator.pop(c);
                        }
                      },
                      child: const Text("Simpan"),
                    ),
                  ],
                ),
              );
            }

            // Helper: Hapus Preset
            void _deletePreset(int index) {
              List<Map<String, dynamic>> updatedList = List.from(userPresets);
              updatedList.removeAt(index);
              AppSettings.saveCustomRotationPresets(updatedList);
              setDialogState(() {
                userPresets = updatedList;
              });
            }

            // Helper: Ganti Nama Preset
            Future<void> _renamePreset(
              int index,
              Map<String, dynamic> preset,
            ) async {
              String newName = preset['name'];
              await showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text("Ganti Nama"),
                  content: TextField(
                    autofocus: true,
                    controller: TextEditingController(text: newName),
                    decoration: const InputDecoration(labelText: "Nama Baru"),
                    onChanged: (v) => newName = v,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (newName.trim().isNotEmpty) {
                          List<Map<String, dynamic>> updatedList = List.from(
                            userPresets,
                          );
                          updatedList[index]['name'] = newName.trim();
                          AppSettings.saveCustomRotationPresets(updatedList);
                          setDialogState(() {
                            userPresets = updatedList;
                          });
                          Navigator.pop(c);
                        }
                      },
                      child: const Text("Simpan"),
                    ),
                  ],
                ),
              );
            }

            // Helper: Update Nilai Preset ke Slider Saat Ini
            void _updatePresetValue(int index) {
              List<Map<String, dynamic>> updatedList = List.from(userPresets);
              updatedList[index]['value'] = currentRotation;
              AppSettings.saveCustomRotationPresets(updatedList);
              setDialogState(() {
                userPresets = updatedList;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Preset "${updatedList[index]['name']}" diupdate ke ${(currentRotation * 180 / math.pi).round()}°',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }

            // Helper: Menu Opsi Preset (Long Press)
            void _showPresetOptions(int index, Map<String, dynamic> preset) {
              showModalBottomSheet(
                context: context,
                builder: (c) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text('Kelola: ${preset['name']}'),
                        subtitle: const Text('Pilih aksi untuk sudut ini'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Ganti Nama'),
                        onTap: () {
                          Navigator.pop(c);
                          _renamePreset(index, preset);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.save_as),
                        title: const Text('Timpa dengan Nilai Slider Saat Ini'),
                        subtitle: Text(
                          'Ubah nilai menjadi ${(currentRotation * 180 / math.pi).round()}°',
                        ),
                        onTap: () {
                          Navigator.pop(c);
                          _updatePresetValue(index);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red),
                        ),
                        // --- MODIFIED: KONFIRMASI SEBELUM HAPUS ---
                        onTap: () {
                          Navigator.pop(c); // Tutup bottom sheet
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Hapus Sudut?"),
                              content: Text(
                                "Apakah Anda yakin ingin menghapus preset \"${preset['name']}\"?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Batal"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx); // Tutup dialog
                                    _deletePreset(index); // Hapus
                                  },
                                  child: const Text("Hapus"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            final int degreeDisplay =
                (currentRotation * 180 / math.pi).round() % 360;

            return AlertDialog(
              title: const Text('Atur Arah Panah'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PREVIEW
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Transform.rotate(
                            angle: currentRotation,
                            child: const Icon(
                              Icons.arrow_upward,
                              size: 64,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SLIDER & INDIKATOR
                      Center(
                        child: Text(
                          "Posisi: $degreeDisplay°",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Slider(
                        value: currentRotation,
                        min: 0.0,
                        max: 2 * math.pi,
                        onChanged: (val) {
                          setDialogState(() => currentRotation = val);
                          setState(() {
                            conn['rotation'] = val;
                            conn.remove('direction');
                          });
                        },
                      ),

                      const Divider(height: 24),

                      // SECTION: DEFAULT PRESETS
                      const Text(
                        "Sudut Default",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: defaultPresets.map((p) {
                          return ActionChip(
                            label: Text(p['label']),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              final double rad =
                                  (p['deg'] as int) * (math.pi / 180);
                              setDialogState(() => currentRotation = rad);
                              setState(() {
                                conn['rotation'] = rad;
                                conn.remove('direction');
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const Divider(height: 24),

                      // SECTION: USER PRESETS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Sudut Pengguna",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.blue,
                            ),
                            tooltip: "Simpan sudut saat ini",
                            onPressed: _addNewPreset,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (userPresets.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "Tekan lama untuk kelola (hapus/edit)",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),

                      if (userPresets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Belum ada sudut tersimpan.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: userPresets.asMap().entries.map((entry) {
                            final index = entry.key;
                            final p = entry.value;
                            // --- MODIFIED: MENGGUNAKAN ACTION CHIP TANPA 'X' ---
                            return GestureDetector(
                              onLongPress: () => _showPresetOptions(index, p),
                              child: ActionChip(
                                label: Text(p['name']),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  final double val = (p['value'] as num)
                                      .toDouble();
                                  setDialogState(() => currentRotation = val);
                                  setState(() {
                                    conn['rotation'] = val;
                                    conn.remove('direction');
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _saveBuildingData();
                    Navigator.pop(context);
                  },
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- EXPORT FUNCTIONS ---
  Future<void> _exportRoomView() async {
    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atur folder export di Pengaturan terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Gagal menangkap tampilan layar.");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final now = DateTime.now();
      final roomName = _currentRoom?['name'] ?? 'room';
      final fileName =
          'room_view_export_${roomName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.png';
      final file = File(p.join(AppSettings.exportPath!, fileName));

      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tampilan berhasil diexport ke: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export tampilan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportOriginalImage() async {
    if (_currentRoom == null || _currentRoom!['image'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruangan ini tidak memiliki gambar background.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atur folder export di Pengaturan terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final originalFile = File(
        p.join(widget.buildingDirectory.path, _currentRoom!['image']),
      );

      if (!await originalFile.exists()) {
        throw Exception("File gambar asli tidak ditemukan di penyimpanan.");
      }

      final now = DateTime.now();
      final roomName = _currentRoom?['name'] ?? 'room';
      final ext = p.extension(originalFile.path);
      final fileName =
          'room_original_${roomName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}$ext';
      final destination = p.join(AppSettings.exportPath!, fileName);

      await originalFile.copy(destination);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gambar asli berhasil diexport ke: $destination'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export gambar asli: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  Future<void> _showEditObjectDialog(Map<String, dynamic> obj) async {
    final nameController = TextEditingController(text: obj['name']);
    final iconTextController = TextEditingController();
    String iconType = obj['icon_type'] ?? 'default';
    String? currentIconData = obj['icon_data'];
    String? tempNewImagePath;

    if (iconType == 'text') iconTextController.text = currentIconData ?? '';

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit: ${obj['name']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Objek'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: iconType,
                    isExpanded: true,
                    items: ['default', 'text', 'image']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => iconType = v!),
                  ),
                  if (iconType == 'text')
                    TextField(
                      controller: iconTextController,
                      decoration: const InputDecoration(labelText: 'Karakter'),
                      maxLength: 2,
                    ),
                  if (iconType == 'image')
                    OutlinedButton(
                      child: const Text('Pilih Foto'),
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (res != null)
                          setDialogState(
                            () => tempNewImagePath = res.files.single.path,
                          );
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  _deleteObject(obj);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  _startMovingObject(obj['id'], obj['name']);
                },
                child: const Text('Pindah'),
              ),
              ElevatedButton(
                onPressed: () {
                  String? finalData;
                  if (iconType == 'text')
                    finalData = iconTextController.text;
                  else if (iconType == 'image')
                    finalData = tempNewImagePath ?? currentIconData;
                  _updateObject(
                    obj,
                    nameController.text,
                    iconType,
                    finalData,
                    isNewImage: tempNewImagePath != null,
                  );
                  Navigator.pop(c);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateObject(
    Map<String, dynamic> obj,
    String newName,
    String newIconType,
    String? newIconData, {
    bool isNewImage = false,
  }) async {
    setState(() {
      obj['name'] = newName;
      obj['icon_type'] = newIconType;
    });
    if (newIconType == 'image' && newIconData != null && isNewImage) {
      final File checkFile = File(newIconData);
      if (checkFile.existsSync()) {
        final objectDir = Directory(
          p.join(_roomObjectsRootDir!.path, obj['id']),
        );
        if (!await objectDir.exists()) await objectDir.create();
        final ext = p.extension(newIconData);
        final fileName = 'marker_${DateTime.now().millisecondsSinceEpoch}$ext';
        await checkFile.copy(p.join(objectDir.path, fileName));
        obj['icon_data'] = fileName;
      }
    } else {
      obj['icon_data'] = newIconData;
    }
    await _saveRoomObjects();
  }

  Future<void> _deleteObject(Map<String, dynamic> obj) async {
    final objectDir = Directory(p.join(_roomObjectsRootDir!.path, obj['id']));
    if (await objectDir.exists()) await objectDir.delete(recursive: true);
    setState(() => _roomObjects.removeWhere((item) => item['id'] == obj['id']));
    await _saveRoomObjects();
  }

  void _openObject(Map<String, dynamic> obj) {
    if (_roomObjectsRootDir == null) return;
    final objectDir = Directory(p.join(_roomObjectsRootDir!.path, obj['id']));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecursiveObjectPage(
          objectDirectory: objectDir,
          objectName: obj['name'] ?? 'Objek',
        ),
      ),
    ).then((_) {
      if (_currentRoom != null) _loadRoomObjects(_currentRoom!['id']);
    });
  }

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
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nama'),
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
              ? 'Mode Edit Aktif: Ketuk Objek/Panah untuk Edit'
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

  // ==========================================
  // BUILDER METHODS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _currentRoom?['name'] ?? 'Viewer',
          style: const TextStyle(
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
        actions: [
          if (_isObjectEditMode && _movingObjectId != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Batal Pindah',
              onPressed: () => setState(() => _movingObjectId = null),
            ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            onSelected: (v) {
              if (v == 'edit') _toggleEditMode();
              if (v == 'icons') setState(() => _showIcons = !_showIcons);
              if (v == 'structure') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => RoomEditorPage(
                      buildingDirectory: widget.buildingDirectory,
                    ),
                  ),
                ).then((_) => _loadData());
              }
              if (v == 'export_view') _exportRoomView();
              if (v == 'export_original') _exportOriginalImage();
            },
            itemBuilder: (c) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      _isObjectEditMode ? Icons.check_circle : Icons.edit,
                      color: _isObjectEditMode ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isObjectEditMode
                          ? 'Selesai Edit'
                          : 'Mode Edit (Geser/Putar)',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'icons',
                child: Row(
                  children: [
                    Icon(
                      _showIcons ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(_showIcons ? 'Sembunyikan Objek' : 'Tampilkan Objek'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'structure',
                child: Row(
                  children: [
                    Icon(Icons.dashboard_customize, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text('Edit Struktur Ruangan'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export_view',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Export Tampilan (PNG)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_original',
                child: Row(
                  children: [
                    Icon(Icons.image, color: Colors.indigo),
                    SizedBox(width: 12),
                    Text('Export Gambar Asli'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RepaintBoundary(
              key: _globalKey,
              child: Stack(
                children: [
                  _buildImmersiveBackground(),
                  _buildOverlay(),
                  _buildInteractiveContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildImmersiveBackground() {
    if (_currentRoom == null)
      return Container(color: Theme.of(context).scaffoldBackgroundColor);

    final imagePath = _currentRoom!['image'];

    if (imagePath != null) {
      final file = File(p.join(widget.buildingDirectory.path, imagePath));
      if (file.existsSync()) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.blurStrength,
          builder: (context, blur, child) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Container(color: Colors.black.withOpacity(0)),
                  ),
                ),
              ],
            );
          },
        );
      }
    }

    final mode = AppSettings.wallpaperMode;

    if (mode == 'gradient') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppSettings.gradientColor1),
              Color(AppSettings.gradientColor2),
            ],
          ),
        ),
      );
    } else if (mode == 'solid') {
      return ValueListenableBuilder<int>(
        valueListenable: AppSettings.solidColor,
        builder: (context, colorVal, child) {
          return Container(color: Color(colorVal));
        },
      );
    }

    return Container(color: Theme.of(context).scaffoldBackgroundColor);
  }

  Widget _buildOverlay() {
    return ValueListenableBuilder<double>(
      valueListenable: AppSettings.backgroundOverlayOpacity,
      builder: (context, opacity, child) {
        return Container(color: Colors.black.withOpacity(opacity));
      },
    );
  }

  Widget _buildInteractiveContent() {
    if (_currentRoom == null) return const Center(child: Text('Error Data'));
    final imagePath = _currentRoom!['image'];
    final connections = _currentRoom!['connections'] as List? ?? [];

    Widget bgImage;
    if (imagePath != null) {
      final file = File(p.join(widget.buildingDirectory.path, imagePath));
      if (file.existsSync()) {
        bgImage = Image.file(file, fit: BoxFit.contain);
      } else {
        bgImage = const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.white54),
        );
      }
    } else {
      bgImage = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              "Tidak ada gambar ruangan",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

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

                if (AppSettings.showNavigationArrows)
                  ...connections.map((conn) {
                    final String label = conn['label'] ?? 'Pintu';
                    final String connId = conn['id'];
                    final double rotation = _getRotation(conn);

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
                            _showRotationDialog(conn);
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
                            rotation,
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

    return GestureDetector(
      onTap: () {
        if (_isObjectEditMode) {
          if (!isMoving) _showEditObjectDialog(obj);
        } else {
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

  Widget _buildArrowWidget(String label, double rotation, bool isDragging) {
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
            child: Transform.rotate(
              angle: rotation,
              child: Icon(
                Icons.arrow_upward,
                size: 48 * scale,
                color: isDragging ? Colors.yellow : color,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
              ),
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
