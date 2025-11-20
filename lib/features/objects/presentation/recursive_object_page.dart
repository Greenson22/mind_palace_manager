// lib/features/objects/presentation/recursive_object_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/objects/presentation/editor/object_room_editor_page.dart';

enum ObjectViewMode { mapContainer, immersiveView }

class RecursiveObjectPage extends StatefulWidget {
  final Directory objectDirectory;
  final String objectName;

  const RecursiveObjectPage({
    super.key,
    required this.objectDirectory,
    required this.objectName,
  });

  @override
  State<RecursiveObjectPage> createState() => _RecursiveObjectPageState();
}

class _RecursiveObjectPageState extends State<RecursiveObjectPage> {
  late File _jsonFile;

  Map<String, dynamic> _objectData = {
    "view_mode": "mapContainer",
    "image_path": null,
    "children": [],
    "rooms": [],
  };

  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isListView = false;

  // --- VISIBILITY STATE ---
  late bool _showIcons;

  // --- STATE PINDAH POSISI ---
  String? _movingChildId;

  File? _backgroundImageFile;
  double _imageAspectRatio = 1.0;

  Map<String, dynamic>? _currentRoom;

  final TransformationController _transformationController =
      TransformationController();

  Offset? _tappedCoords;

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.objectDirectory.path, 'object_data.json'));
    _showIcons = AppSettings.defaultShowObjectIcons;
    _loadData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // --- DATA MANAGEMENT ---

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _movingChildId = null;
    try {
      if (!await widget.objectDirectory.exists()) {
        await widget.objectDirectory.create(recursive: true);
      }

      if (await _jsonFile.exists()) {
        final content = await _jsonFile.readAsString();
        _objectData = json.decode(content);

        if (_objectData['view_mode'] == 'mapContainer') {
          final imgName = _objectData['image_path'];
          if (imgName != null) {
            _backgroundImageFile = File(
              p.join(widget.objectDirectory.path, imgName),
            );
            if (await _backgroundImageFile!.exists()) {
              await _updateImageAspectRatio(_backgroundImageFile!);
            } else {
              _backgroundImageFile = null;
            }
          }
        } else {
          final rooms = _objectData['rooms'] as List? ?? [];
          if (rooms.isNotEmpty) {
            if (_currentRoom == null) {
              _currentRoom = rooms[0];
            } else {
              _currentRoom = rooms.firstWhere(
                (r) => r['id'] == _currentRoom!['id'],
                orElse: () => rooms[0],
              );
            }
          } else {
            _currentRoom = null;
          }
        }
      } else {
        await _saveData();
      }
    } catch (e) {
      debugPrint("Error loading object data: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    await _jsonFile.writeAsString(json.encode(_objectData));
  }

  Future<void> _updateImageAspectRatio(File imageFile) async {
    try {
      final data = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _imageAspectRatio = frame.image.width / frame.image.height;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _imageAspectRatio = 1.0);
    }
  }

  // --- LOGIKA PINDAH POSISI ---
  void _startMovingChild(String id, String name) {
    setState(() {
      _movingChildId = id;
      _tappedCoords = null;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Memindahkan '$name'. Ketuk lokasi baru."),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmMoveChild(double x, double y) async {
    if (_movingChildId == null) return;

    final children = _objectData['children'] as List;
    final index = children.indexWhere((c) => c['id'] == _movingChildId);

    if (index != -1) {
      setState(() {
        children[index]['x'] = x;
        children[index]['y'] = y;
        _movingChildId = null;
      });
      await _saveData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Posisi disimpan.")));
      }
    }
  }

  void _cancelMove() {
    setState(() {
      _movingChildId = null;
    });
  }

  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final extension = p.extension(sourceFile.path);
      final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}$extension';
      final destPath = p.join(widget.objectDirectory.path, fileName);

      if (_objectData['image_path'] != null) {
        final oldFile = File(
          p.join(widget.objectDirectory.path, _objectData['image_path']),
        );
        if (await oldFile.exists()) await oldFile.delete();
      }

      await sourceFile.copy(destPath);
      _objectData['image_path'] = fileName;
      _backgroundImageFile = File(destPath);
      await _updateImageAspectRatio(_backgroundImageFile!);
      await _saveData();
      setState(() {});
    }
  }

  void _toggleParentViewMode() {
    setState(() {
      final current = _objectData['view_mode'];
      _objectData['view_mode'] = current == 'mapContainer'
          ? 'immersiveView'
          : 'mapContainer';

      _tappedCoords = null;
      _backgroundImageFile = null;
      _currentRoom = null;

      _saveData();
      _loadData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mode Objek INI diubah ke: ${_objectData['view_mode'] == 'mapContainer' ? 'Wadah (Peta)' : 'Lokasi (Immersive)'}',
        ),
      ),
    );
  }

  Future<void> _createNewChild(String name, String viewMode) async {
    double x = 0.5;
    double y = 0.5;

    if (_tappedCoords != null) {
      x = _tappedCoords!.dx;
      y = _tappedCoords!.dy;
    }

    final folderName = 'obj_${DateTime.now().millisecondsSinceEpoch}';
    final childDir = Directory(p.join(widget.objectDirectory.path, folderName));
    await childDir.create();

    final childJson = File(p.join(childDir.path, 'object_data.json'));
    await childJson.writeAsString(
      json.encode({"view_mode": viewMode, "children": [], "rooms": []}),
    );

    String? parentRoomId;
    if (_objectData['view_mode'] == 'immersiveView' && _currentRoom != null) {
      parentRoomId = _currentRoom!['id'];
    } else {
      parentRoomId = null;
    }

    final newChild = {
      "id": folderName,
      "name": name,
      "x": x,
      "y": y,
      "type": viewMode,
      "parent_room_id": parentRoomId,
      "icon_type": "default",
      "icon_data": null, // Digunakan untuk nama file gambar atau string teks
    };

    setState(() {
      (_objectData['children'] as List).add(newChild);
      _tappedCoords = null;
    });

    await _saveData();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Objek "$name" ditambahkan.')));
    }
  }

  // --- UPDATED: Dialog Edit Child untuk mendukung Teks & Gambar ---
  Future<void> _showEditChildDialog(Map<String, dynamic> child) async {
    final nameController = TextEditingController(text: child['name']);
    final iconTextController = TextEditingController();

    String selectedType = child['type'] ?? 'mapContainer';
    String iconType = child['icon_type'] ?? 'default';

    // Handling data lama (icon_path) vs data baru (icon_data)
    dynamic currentIconData = child['icon_data'] ?? child['icon_path'];

    // Temp variable untuk gambar baru
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
              title: Text('Edit: ${child['name']}'),
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

                    // Input jika Teks
                    if (iconType == 'text')
                      TextField(
                        controller: iconTextController,
                        decoration: const InputDecoration(
                          labelText: 'Karakter (Emoji/Huruf)',
                          hintText: 'Contoh: 📦',
                        ),
                        maxLength: 2,
                      ),

                    // Input jika Gambar
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
                    _deleteChild(child);
                  },
                  child: const Text('Hapus'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_with),
                  label: const Text('Pindah'),
                  onPressed: () {
                    Navigator.pop(c);
                    _startMovingChild(child['id'], child['name']);
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      Navigator.pop(c);

                      // Tentukan data ikon yang akan disimpan
                      String? finalIconData;

                      if (iconType == 'text') {
                        finalIconData = iconTextController.text;
                      } else if (iconType == 'image') {
                        // Jika ada gambar baru, gunakan path sementaranya
                        // Nanti _updateChild yang akan copy file-nya
                        finalIconData = tempNewImagePath ?? currentIconData;
                      }

                      _updateChild(
                        child,
                        nameController.text.trim(),
                        selectedType,
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

  // --- UPDATED: Update Logic untuk handle Teks & Gambar ---
  Future<void> _updateChild(
    Map<String, dynamic> child,
    String newName,
    String newType,
    String newIconType,
    String? newIconData, {
    bool isNewImage = false,
  }) async {
    setState(() {
      child['name'] = newName;
      child['type'] = newType;
      child['icon_type'] = newIconType;
    });

    // Proses penyimpanan Icon Data
    if (newIconType == 'image' && newIconData != null && isNewImage) {
      // Jika gambar baru dipilih, copy ke folder objek
      final File checkFile = File(newIconData);
      if (checkFile.existsSync()) {
        final childDir = Directory(
          p.join(widget.objectDirectory.path, child['id']),
        );
        if (!await childDir.exists()) await childDir.create();

        final ext = p.extension(newIconData);
        final fileName = 'marker_${DateTime.now().millisecondsSinceEpoch}$ext';
        final destPath = p.join(childDir.path, fileName);

        await checkFile.copy(destPath);
        child['icon_data'] = fileName; // Simpan nama file saja
      }
    } else if (newIconType == 'text') {
      // Jika teks, simpan string langsung
      child['icon_data'] = newIconData;
    } else if (newIconType == 'default') {
      child['icon_data'] = null;
    } else {
      // Case: Image tapi tidak ganti gambar (keep existing filename)
      child['icon_data'] = newIconData;
    }

    // Bersihkan field legacy jika ada
    child.remove('icon_path');

    // Update metadata di dalam file anak juga (opsional, agar sinkron)
    try {
      final childJson = File(
        p.join(widget.objectDirectory.path, child['id'], 'object_data.json'),
      );
      if (await childJson.exists()) {
        final content = await childJson.readAsString();
        final data = json.decode(content);
        data['view_mode'] = newType;
        await childJson.writeAsString(json.encode(data));
      }
    } catch (_) {}

    await _saveData();
    setState(() {});
  }

  Future<void> _deleteChild(Map<String, dynamic> child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Objek?'),
        content: Text('"${child['name']}" akan dihapus permanen.'),
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
      final childDir = Directory(
        p.join(widget.objectDirectory.path, child['id']),
      );
      if (await childDir.exists()) {
        await childDir.delete(recursive: true);
      }
      setState(() {
        (_objectData['children'] as List).removeWhere(
          (e) => e['id'] == child['id'],
        );
        if (_movingChildId == child['id']) _movingChildId = null;
      });
      await _saveData();
    }
  }

  void _handleChildTap(Map<String, dynamic> child) {
    if (_isEditMode) {
      if (_movingChildId != null) return;
      _showEditChildDialog(child);
    } else {
      _openChildObject(child);
    }
  }

  void _openChildObject(Map<String, dynamic> child) {
    final childDir = Directory(
      p.join(widget.objectDirectory.path, child['id']),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecursiveObjectPage(
          objectDirectory: childDir,
          objectName: child['name'],
        ),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToRoom(String roomId) {
    final rooms = _objectData['rooms'] as List? ?? [];
    try {
      final target = rooms.firstWhere((r) => r['id'] == roomId);
      setState(() {
        _currentRoom = target;
        _tappedCoords = null;
        _isEditMode = false;
        _movingChildId = null;
      });
    } catch (_) {}
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    String selectedType = 'mapContainer';

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Objek/Isi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Objek',
                  hintText: 'Contoh: Buku, Laci',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Tipe Tampilan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Wadah (Container)'),
                subtitle: const Text('Pin di atas gambar.'),
                value: 'mapContainer',
                groupValue: selectedType,
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
              RadioListTile<String>(
                title: const Text('Lokasi (Immersive)'),
                subtitle: const Text('Navigasi masuk ke dalam.'),
                value: 'immersiveView',
                groupValue: selectedType,
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(c);
                  _createNewChild(nameController.text.trim(), selectedType);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRoomEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) =>
            ObjectRoomEditorPage(objectDirectory: widget.objectDirectory),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final isMapMode = _objectData['view_mode'] == 'mapContainer';

    Widget mainContent;

    if (_isLoading) {
      mainContent = const Center(child: CircularProgressIndicator());
    } else if (_isListView) {
      mainContent = _buildListView();
    } else {
      if (isMapMode) {
        mainContent = _buildInteractiveCanvas(true);
      } else {
        mainContent = Column(
          children: [
            Expanded(child: _buildImmersiveRoomCanvas()),
            _buildBottomNavigationPanel(),
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.objectName, style: const TextStyle(fontSize: 16)),
            Text(
              isMapMode ? '(Mode Wadah)' : '(Mode Lokasi)',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          if (_isEditMode && _movingChildId != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Batal Pindah',
              onPressed: _cancelMove,
            ),

          IconButton(
            icon: Icon(_isListView ? Icons.map : Icons.list),
            tooltip: _isListView ? 'Lihat Peta/Gambar' : 'Lihat Daftar Objek',
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
                if (_isListView) _tappedCoords = null;
              });
            },
          ),

          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'toggle_edit':
                  setState(() {
                    _isEditMode = !_isEditMode;
                    _tappedCoords = null;
                    _movingChildId = null;
                  });
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isEditMode
                            ? 'Mode Edit: Ketuk untuk edit.'
                            : 'Mode Lihat Aktif',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  break;
                case 'change_type':
                  _toggleParentViewMode();
                  break;
                case 'change_image':
                  _pickBackgroundImage();
                  break;
                case 'manage_rooms':
                  _navigateToRoomEditor();
                  break;
                case 'toggle_icons':
                  setState(() => _showIcons = !_showIcons);
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'toggle_edit',
                  child: Row(
                    children: [
                      Icon(
                        _isEditMode ? Icons.check_circle : Icons.edit,
                        color: _isEditMode ? Colors.green : null,
                      ),
                      const SizedBox(width: 8),
                      Text(_isEditMode ? 'Selesai Edit Isi' : 'Mode Edit Isi'),
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
                PopupMenuItem(
                  value: 'change_type',
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz),
                      const SizedBox(width: 8),
                      Text(
                        isMapMode
                            ? 'Ubah ke Mode Lokasi'
                            : 'Ubah ke Mode Wadah',
                      ),
                    ],
                  ),
                ),
                if (isMapMode)
                  const PopupMenuItem(
                    value: 'change_image',
                    child: Row(
                      children: [
                        Icon(Icons.image),
                        SizedBox(width: 8),
                        Text('Ganti Gambar Wadah'),
                      ],
                    ),
                  ),
                if (!isMapMode)
                  const PopupMenuItem(
                    value: 'manage_rooms',
                    child: Row(
                      children: [
                        Icon(Icons.meeting_room),
                        SizedBox(width: 8),
                        Text('Kelola Ruangan'),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isEditMode)
            Container(
              color: _movingChildId != null
                  ? Colors.blue.shade100
                  : Theme.of(context).colorScheme.surfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: double.infinity,
              child: Text(
                _movingChildId != null
                    ? "MODE PINDAH: Ketuk lokasi baru untuk meletakkan."
                    : "Mode Edit Aktif: Ketuk objek untuk edit.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _movingChildId != null ? Colors.blue : null,
                  fontWeight: _movingChildId != null ? FontWeight.bold : null,
                ),
              ),
            ),
          Expanded(child: mainContent),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(isMapMode),
    );
  }

  Widget? _buildFloatingActionButton(bool isMapMode) {
    if (!_isEditMode) return null;

    bool canAdd =
        _isListView ||
        (isMapMode && _tappedCoords != null && _movingChildId == null) ||
        (!isMapMode && _tappedCoords != null && _movingChildId == null);

    if (canAdd) {
      return FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Objek'),
      );
    }
    return null;
  }

  Widget _buildListView() {
    final children = _objectData['children'] as List? ?? [];

    if (children.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada isi/objek.\nMasuk Mode Edit untuk menambahkan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        final type = child['type'] ?? 'mapContainer';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: type == 'mapContainer'
                ? Colors.blue.shade100
                : Colors.orange.shade100,
            child: Icon(
              type == 'mapContainer' ? Icons.inbox : Icons.touch_app,
              color: type == 'mapContainer' ? Colors.blue : Colors.orange,
            ),
          ),
          title: Text(child['name']),
          subtitle: Text(
            type == 'mapContainer' ? 'Tipe: Wadah' : 'Tipe: Lokasi',
          ),
          trailing: _isEditMode
              ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () => _showEditChildDialog(child),
                )
              : const Icon(Icons.chevron_right),
          onTap: () => _handleChildTap(child),
        );
      },
    );
  }

  Widget _buildImmersiveRoomCanvas() {
    if (_currentRoom == null) {
      return const Center(
        child: Text('Belum ada ruangan.\nKlik tombol menu > Kelola Ruangan.'),
      );
    }

    final roomImgPath = _currentRoom!['image'];
    final allChildren = _objectData['children'] as List? ?? [];
    final roomChildren = allChildren
        .where((c) => c['parent_room_id'] == _currentRoom!['id'])
        .toList();

    File? roomFile;
    if (roomImgPath != null) {
      final f = File(p.join(widget.objectDirectory.path, roomImgPath));
      if (f.existsSync()) roomFile = f;
    }

    if (roomFile == null) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
      );
    }

    return _buildInteractiveArea(
      imageFile: roomFile,
      children: roomChildren,
      isMapStyle: false,
    );
  }

  Widget _buildInteractiveCanvas(bool isMapStyle) {
    if (_backgroundImageFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Belum ada gambar wadah.'),
            if (_isEditMode)
              ElevatedButton(
                onPressed: _pickBackgroundImage,
                child: const Text('Upload Gambar'),
              ),
          ],
        ),
      );
    }

    return _buildInteractiveArea(
      imageFile: _backgroundImageFile!,
      children: _objectData['children'] as List? ?? [],
      isMapStyle: isMapStyle,
    );
  }

  Widget _buildInteractiveArea({
    required File imageFile,
    required List children,
    required bool isMapStyle,
  }) {
    double finalOpacity;
    if (_isEditMode) {
      finalOpacity = 1.0;
    } else {
      finalOpacity = _showIcons ? AppSettings.objectIconOpacity : 0.0;
    }

    bool isInteractable;
    if (_isEditMode) {
      isInteractable = true;
    } else {
      isInteractable = _showIcons ? true : AppSettings.interactableWhenHidden;
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: _isEditMode
                  ? (details) {
                      final x = details.localPosition.dx / constraints.maxWidth;
                      final y =
                          details.localPosition.dy / constraints.maxHeight;

                      // LOGIKA PINDAH
                      if (_movingChildId != null) {
                        _confirmMoveChild(x, y);
                      } else {
                        setState(() {
                          _tappedCoords = Offset(x, y);
                        });
                      }
                    }
                  : null,

              child: Stack(
                children: [
                  Image.file(
                    imageFile,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.contain,
                  ),

                  ...children.map((child) {
                    final double x = child['x'] ?? 0.5;
                    final double y = child['y'] ?? 0.5;

                    return Positioned(
                      left: x * constraints.maxWidth - 20,
                      top: y * constraints.maxHeight - 20,
                      child: IgnorePointer(
                        ignoring: !isInteractable,
                        child: Opacity(
                          opacity: finalOpacity,
                          child: _buildChildWidget(
                            child,
                            constraints,
                            isMapStyle,
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  if (_isEditMode &&
                      _tappedCoords != null &&
                      _movingChildId == null)
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
            );
          },
        ),
      ),
    );
  }

  // --- UPDATED: Build Widget untuk mendukung render Teks & Gambar ---
  Widget _buildChildWidget(
    Map<String, dynamic> child,
    BoxConstraints constraints,
    bool isMapStyle,
  ) {
    final String name = child['name'];
    final String type = child['type'] ?? 'mapContainer';

    final String iconType = child['icon_type'] ?? 'default';
    // Support legacy (icon_path) vs new (icon_data)
    final String? iconData = child['icon_data'] ?? child['icon_path'];

    final bool isMoving = (child['id'] == _movingChildId);

    final IconData defaultIcon = type == 'mapContainer'
        ? Icons.inbox
        : Icons.touch_app;
    final Color color = type == 'mapContainer' ? Colors.blue : Colors.orange;

    Widget childContent;

    if (iconType == 'image' && iconData != null) {
      // RENDER GAMBAR
      final file = File(
        p.join(widget.objectDirectory.path, child['id'], iconData),
      );
      if (file.existsSync()) {
        childContent = Container(
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
          child: _isEditMode && !isMoving
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
        childContent = _buildDefaultMarker(
          defaultIcon,
          color,
          isMapStyle,
          isMoving,
        );
      }
    } else if (iconType == 'text' && iconData != null) {
      // RENDER TEKS / EMOJI
      childContent = Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isMoving ? Colors.green : color.withOpacity(0.9),
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
            if (_isEditMode && !isMoving)
              const Icon(Icons.edit, color: Colors.white70, size: 14),
          ],
        ),
      );
    } else {
      // RENDER DEFAULT
      childContent = _buildDefaultMarker(
        defaultIcon,
        color,
        isMapStyle,
        isMoving,
      );
    }

    // Jika bukan map style dan bukan gambar (atau jika user mau label tetap muncul)
    // Kita tambahkan label nama di bawahnya
    if (!isMapStyle && iconType != 'image') {
      childContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          childContent,
          if (_isEditMode ||
              (_showIcons && AppSettings.showRegionDistrictNames))
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isMoving ? Colors.green : Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isMoving ? "Pindahkan..." : name,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _handleChildTap(child),
      child: Tooltip(
        message: "$name (${type == 'mapContainer' ? 'Wadah' : 'Lokasi'})",
        child: childContent,
      ),
    );
  }

  Widget _buildDefaultMarker(
    IconData icon,
    Color color,
    bool isMapStyle,
    bool isMoving,
  ) {
    if (isMapStyle) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isMoving ? Colors.green : color.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isMoving ? Colors.greenAccent : Colors.white,
            width: isMoving ? 3 : 2,
          ),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Icon(
          _isEditMode && !isMoving ? Icons.edit : icon,
          color: Colors.white,
          size: 20,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isMoving
              ? Colors.green.withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: isMoving ? Colors.greenAccent : color,
            width: isMoving ? 3 : 2,
          ),
        ),
        child: Icon(
          _isEditMode && !isMoving ? Icons.edit : icon,
          color: isMoving ? Colors.white : color,
          size: 24,
        ),
      );
    }
  }

  Widget _buildBottomNavigationPanel() {
    final connections = _currentRoom?['connections'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.1)),
        ],
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Navigasi di ${_currentRoom?['name']}:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_isEditMode)
                SizedBox(
                  height: 32,
                  child: FilledButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Tambah"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (connections.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: connections.map<Widget>((conn) {
                return ActionChip(
                  avatar: const Icon(Icons.meeting_room, size: 16),
                  label: Text(conn['label']),
                  onPressed: () => _navigateToRoom(conn['targetRoomId']),
                );
              }).toList(),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Tidak ada pintu navigasi.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
