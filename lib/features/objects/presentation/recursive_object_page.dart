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
  // ------------------------

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

  // --- ACTIONS ---

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

  // --- FUNGSI TAMBAH / EDIT CHILD ---

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
      "icon_path": null,
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

  Future<void> _showEditChildDialog(Map<String, dynamic> child) async {
    final nameController = TextEditingController(text: child['name']);
    String selectedType = child['type'] ?? 'mapContainer';
    String iconType = child['icon_type'] ?? 'default';
    String? tempIconPath = child['icon_path'];

    String getIconStatusText() {
      if (iconType == 'image' && tempIconPath != null) {
        return 'Gambar terpilih: ${p.basename(tempIconPath!)}';
      }
      return 'Menggunakan Ikon Standar';
    }

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        const Text('Foto'),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      Navigator.pop(c);
                      _updateChild(
                        child,
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

  Future<void> _updateChild(
    Map<String, dynamic> child,
    String newName,
    String newType,
    String newIconType,
    String? newIconPath,
  ) async {
    setState(() {
      child['name'] = newName;
      child['type'] = newType;
      child['icon_type'] = newIconType;
    });

    if (newIconType == 'image' && newIconPath != null) {
      final File checkFile = File(newIconPath);
      if (checkFile.isAbsolute && await checkFile.exists()) {
        final childDir = Directory(
          p.join(widget.objectDirectory.path, child['id']),
        );
        if (!await childDir.exists()) await childDir.create();

        final ext = p.extension(newIconPath);
        final fileName = 'marker_${DateTime.now().millisecondsSinceEpoch}$ext';
        final destPath = p.join(childDir.path, fileName);

        await checkFile.copy(destPath);
        child['icon_path'] = fileName;
      } else {
        child['icon_path'] = newIconPath;
      }
    } else {
      child['icon_path'] = null;
    }

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
      });
      await _saveData();
    }
  }

  void _handleChildTap(Map<String, dynamic> child) {
    if (_isEditMode) {
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
                  setState(() => _isEditMode = !_isEditMode);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isEditMode
                            ? 'Mode Edit: Ketuk objek untuk ubah'
                            : 'Mode Lihat Aktif',
                      ),
                      duration: const Duration(seconds: 1),
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
              color: Theme.of(context).colorScheme.surfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: double.infinity,
              child: const Text(
                "Mode Edit Aktif: Ketuk untuk edit, Tahan untuk hapus.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
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
        (isMapMode && _tappedCoords != null) ||
        (!isMapMode && _tappedCoords != null);

    if (canAdd) {
      return FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Objek'),
      );
    }
    return null;
  }

  // --- WIDGET YANG SEBELUMNYA HILANG: _buildListView ---
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
                      final local = details.localPosition;
                      setState(() {
                        _tappedCoords = Offset(
                          local.dx / constraints.maxWidth,
                          local.dy / constraints.maxHeight,
                        );
                      });
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

                  if (_isEditMode && _tappedCoords != null)
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

  Widget _buildChildWidget(
    Map<String, dynamic> child,
    BoxConstraints constraints,
    bool isMapStyle,
  ) {
    final String name = child['name'];
    final String type = child['type'] ?? 'mapContainer';
    final String iconType = child['icon_type'] ?? 'default';
    final String? iconPath = child['icon_path'];

    final IconData defaultIcon = type == 'mapContainer'
        ? Icons.inbox
        : Icons.touch_app;
    final Color color = type == 'mapContainer' ? Colors.blue : Colors.orange;

    Widget childContent;

    if (iconType == 'image' && iconPath != null) {
      final file = File(
        p.join(widget.objectDirectory.path, child['id'], iconPath),
      );
      if (file.existsSync()) {
        childContent = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
          child: _isEditMode
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
        childContent = _buildDefaultMarker(defaultIcon, color, isMapStyle);
      }
    } else {
      childContent = _buildDefaultMarker(defaultIcon, color, isMapStyle);
    }

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
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                name,
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

  Widget _buildDefaultMarker(IconData icon, Color color, bool isMapStyle) {
    if (isMapStyle) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Icon(
          _isEditMode ? Icons.edit : icon,
          color: Colors.white,
          size: 20,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(_isEditMode ? Icons.edit : icon, color: color, size: 24),
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
