// lib/features/building/presentation/viewer/building_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // Import File Picker
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
  bool _isObjectEditMode = false; // Mode Edit Objek
  List<dynamic> _roomObjects = []; // Daftar objek yang ditaruh di ruangan ini
  File? _roomObjectsJsonFile; // File penyimpanan data objek
  Directory? _roomObjectsRootDir; // Folder root objek untuk ruangan ini
  Offset? _tappedCoords; // Koordinat tap saat mode edit untuk ADD baru

  // Controller untuk Zoom/Pan Gambar Ruangan
  final TransformationController _transformationController =
      TransformationController();

  List<dynamic> get _rooms => _buildingData['rooms'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.buildingDirectory.path, 'data.json'));
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

  // --- LOGIKA MUAT & SIMPAN OBJEK ---

  Future<void> _loadRoomObjects(String roomId) async {
    _roomObjects = [];
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

  // --- FUNGSI: TAMBAH OBJEK BARU ---

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
                      hintText: 'Contoh: Lemari, Laci, Pintu Rahasia',
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
                    subtitle: const Text('Seperti Distrik. Berisi item lain.'),
                    value: 'mapContainer',
                    groupValue: selectedType,
                    onChanged: (val) =>
                        setDialogState(() => selectedType = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Lokasi (Immersive)'),
                    subtitle: const Text(
                      'Seperti Ruangan. Bisa masuk ke dalam.',
                    ),
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

    // Buat file config di dalam folder objek anak
    final childJsonFile = File(p.join(childDir.path, 'object_data.json'));
    await childJsonFile.writeAsString(
      json.encode({"view_mode": viewMode, "image_path": null, "children": []}),
    );

    // Data yang disimpan di list induk (Ruangan)
    final newObject = {
      "id": folderId,
      "name": name,
      "x": _tappedCoords!.dx,
      "y": _tappedCoords!.dy,
      "type": viewMode,
      "icon_type": "default", // default | image
      "icon_path": null, // path relatif jika image
    };

    setState(() {
      _roomObjects.add(newObject);
      _tappedCoords = null;
    });

    await _saveRoomObjects();
  }

  // --- FUNGSI: EDIT / HAPUS OBJEK (BARU) ---

  Future<void> _showEditObjectDialog(Map<String, dynamic> obj) async {
    final nameController = TextEditingController(text: obj['name']);
    String selectedType = obj['type'] ?? 'mapContainer';
    String iconType = obj['icon_type'] ?? 'default';
    String? tempIconPath = obj['icon_path'];

    // Helper untuk display path
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
                    // 1. Ganti Nama
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Objek',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Ganti Tipe Perilaku
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

                    // 3. Ganti Ikon (Marker)
                    const Text(
                      'Tampilan Ikon (Marker):',
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
                                  // Simpan path absolut sementara (akan dicopy saat save)
                                  tempIconPath = res.files.single.path!;
                                  // Tandai kalau ini file baru (bukan path relatif yang sudah ada)
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                // Tombol Hapus
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteObject(obj);
                  },
                  child: const Text('Hapus Objek'),
                ),
                // Tombol Simpan
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
    String? newIconPath, // Bisa absolute (baru) atau relative (lama)
  ) async {
    // 1. Update Referensi di List Induk (_roomObjects)
    setState(() {
      originalObj['name'] = newName;
      originalObj['type'] = newType;
      originalObj['icon_type'] = newIconType;
    });

    // 2. Handle Copy Gambar jika ada gambar baru yang dipilih
    if (newIconType == 'image' && newIconPath != null) {
      final File checkFile = File(newIconPath);
      // Jika path yang dikirim adalah path absolute (file baru dari picker)
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

        // Update path di object menjadi relatif terhadap folder objek
        // Struktur: room_objects/{roomId}/{objId}/marker_icon.png
        // Kita simpan relatif terhadap root folder objek (objId)
        // Tapi di list induk, lebih mudah simpan relatif terhadap folder ruangan atau nama file saja
        originalObj['icon_path'] = fileName;
      } else {
        // Jika tidak berubah (masih path relatif lama), biarkan
        originalObj['icon_path'] = newIconPath;
      }
    } else {
      // Reset icon path jika kembali ke default
      originalObj['icon_path'] = null;
    }

    // 3. Simpan List Induk
    await _saveRoomObjects();

    // 4. Update Config Anak (agar tipe/behavior konsisten saat masuk)
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

        // Update view_mode sesuai tipe baru
        data['view_mode'] = newType;

        await childJsonFile.writeAsString(json.encode(data));
      }
    } catch (e) {
      print("Gagal update config anak: $e");
    }

    setState(() {}); // Refresh UI
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
      });
      await _saveRoomObjects();
    }
  }

  // --- NAVIGASI ---

  void _navigateToRoom(String targetRoomId) async {
    try {
      final targetRoom = _rooms.firstWhere((r) => r['id'] == targetRoomId);
      setState(() {
        _currentRoom = targetRoom;
        _isObjectEditMode = false;
        _tappedCoords = null;
      });
      await _loadRoomObjects(targetRoomId);
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
      // Mode Edit: Buka Editor
      _showEditObjectDialog(obj);
    } else {
      // Mode Lihat: Masuk ke Objek
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

  // --- UI BUILDERS ---

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
          // Tombol Toggle Mode Edit Objek
          IconButton(
            icon: Icon(_isObjectEditMode ? Icons.done : Icons.edit_attributes),
            tooltip: _isObjectEditMode
                ? 'Selesai Mengedit'
                : 'Edit Objek (Tambah/Hapus/Ubah)',
            color: _isObjectEditMode ? Colors.green : null,
            onPressed: () {
              setState(() {
                _isObjectEditMode = !_isObjectEditMode;
                _tappedCoords = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isObjectEditMode
                        ? 'Mode Edit: Ketuk objek untuk ubah, ketuk kosong untuk tambah.'
                        : 'Mode Lihat Aktif',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _navigateToRoomEditor();
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit Struktur Ruangan'),
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

    return Column(
      children: [
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
                        // 1. GAMBAR RUANGAN + DETECTOR TAP
                        GestureDetector(
                          onTapDown: (details) {
                            if (_isObjectEditMode) {
                              // Hitung koordinat relatif untuk ADD NEW OBJECT
                              setState(() {
                                _tappedCoords = Offset(
                                  details.localPosition.dx /
                                      constraints.maxWidth,
                                  details.localPosition.dy /
                                      constraints.maxHeight,
                                );
                              });
                              _showAddObjectDialog();
                            }
                          },
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: imageWidget,
                          ),
                        ),

                        // 2. RENDER OBJEK
                        ..._roomObjects.map((obj) {
                          final double x = obj['x'] ?? 0.5;
                          final double y = obj['y'] ?? 0.5;
                          final String type = obj['type'] ?? 'mapContainer';
                          final String name = obj['name'] ?? 'Objek';
                          final String iconType = obj['icon_type'] ?? 'default';
                          final String? iconPath = obj['icon_path'];

                          // Widget Icon Default
                          final IconData defaultIconData =
                              type == 'mapContainer'
                              ? Icons.inbox
                              : Icons.touch_app;
                          final Color defaultColor = type == 'mapContainer'
                              ? Colors.blue
                              : Colors.orange;

                          Widget markerWidget;

                          // Cek apakah menggunakan Custom Image
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
                                    color: Colors.white,
                                    width: 2,
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
                                  ),
                                ),
                                child: _isObjectEditMode
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
                              // Fallback jika file hilang
                              markerWidget = _buildDefaultMarker(
                                defaultIconData,
                                defaultColor,
                              );
                            }
                          } else {
                            // Default Marker
                            markerWidget = _buildDefaultMarker(
                              defaultIconData,
                              defaultColor,
                            );
                          }

                          return Positioned(
                            left: x * constraints.maxWidth - 20,
                            top: y * constraints.maxHeight - 20,
                            child: GestureDetector(
                              onTap: () => _handleObjectTap(obj),
                              // Long press juga bisa trigger edit/delete sebagai shortcut
                              onLongPress: _isObjectEditMode
                                  ? () => _deleteObject(obj)
                                  : null,
                              child: Tooltip(
                                message: name,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    markerWidget,
                                    // Label Nama (Selalu muncul di edit mode, opsional di view mode)
                                    if (_isObjectEditMode ||
                                        AppSettings.showRegionDistrictNames)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          name,
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
                          );
                        }).toList(),

                        // 3. INDIKATOR TAP (Hanya visual sesaat sebelum dialog muncul)
                        if (_isObjectEditMode && _tappedCoords != null)
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

        // Panel Navigasi Ruangan
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

  Widget _buildDefaultMarker(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Icon(
        _isObjectEditMode
            ? Icons.edit
            : icon, // Icon berubah jadi pensil saat edit mode
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
