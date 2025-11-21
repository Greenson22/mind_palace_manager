// lib/features/objects/presentation/editor/object_room_editor_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';

class ObjectRoomEditorPage extends StatefulWidget {
  final Directory objectDirectory;

  const ObjectRoomEditorPage({super.key, required this.objectDirectory});

  @override
  State<ObjectRoomEditorPage> createState() => _ObjectRoomEditorPageState();
}

class _ObjectRoomEditorPageState extends State<ObjectRoomEditorPage> {
  late File _jsonFile;
  Map<String, dynamic> _objectData = {};
  bool _isLoading = true;
  bool _isReorderMode = false;
  final TextEditingController _roomNameController = TextEditingController();
  String? _pickedImagePath;

  List<dynamic> get _rooms => _objectData['rooms'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.objectDirectory.path, 'object_data.json'));
    _loadData();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  // ... (Bagian loadData, saveData, showAddRoomDialog, createRoom, showEditRoomDialog, updateRoom, exportRoomImage, deleteRoom TETAP SAMA) ...
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (await _jsonFile.exists()) {
        final content = await _jsonFile.readAsString();
        _objectData = json.decode(content);
      } else {
        _objectData = {
          "view_mode": "immersiveView",
          "rooms": [],
          "children": [],
        };
      }
      _objectData['rooms'] ??= [];
      for (var room in _rooms) {
        room['connections'] ??= [];
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    await _jsonFile.writeAsString(json.encode(_objectData));
  }

  Future<void> _showAddRoomDialog() async {
    _roomNameController.clear();
    _pickedImagePath = null;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Ruangan Dalam Objek'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(hintText: 'Nama Ruangan'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Pilih Gambar'),
                  onPressed: () async {
                    var res = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (res != null) {
                      setDialogState(
                        () => _pickedImagePath = res.files.single.path,
                      );
                    }
                  },
                ),
                if (_pickedImagePath != null)
                  Text(
                    p.basename(_pickedImagePath!),
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: _createRoom,
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.isEmpty) return;
    Navigator.pop(context);
    String? relativePath;
    if (_pickedImagePath != null) {
      final ext = p.extension(_pickedImagePath!);
      final fileName = 'room_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(
        _pickedImagePath!,
      ).copy(p.join(widget.objectDirectory.path, fileName));
      relativePath = fileName;
    }
    final newRoom = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _roomNameController.text.trim(),
      'image': relativePath,
      'connections': [],
    };
    setState(() => _rooms.add(newRoom));
    await _saveData();
  }

  Future<void> _showEditRoomDialog(Map<String, dynamic> room) async {
    _roomNameController.text = room['name'] ?? '';
    _pickedImagePath = null;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String currentImageName = room['image'] == null
                ? 'Tidak ada gambar'
                : 'Saat ini: ${room['image']}';
            if (_pickedImagePath != null) {
              currentImageName = 'Baru: ${p.basename(_pickedImagePath!)}';
            } else if (_pickedImagePath == 'DELETE_IMAGE') {
              currentImageName = 'Gambar akan dihapus';
            }
            return AlertDialog(
              title: Text('Ubah Ruangan: ${room['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Ruangan Baru',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar Baru'),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        if (result != null &&
                            result.files.single.path != null) {
                          setDialogState(() {
                            _pickedImagePath = result.files.single.path!;
                          });
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        currentImageName,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (room['image'] != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            if (_pickedImagePath != 'DELETE_IMAGE') {
                              _pickedImagePath = 'DELETE_IMAGE';
                            } else {
                              _pickedImagePath = null;
                            }
                          });
                        },
                        child: Text(
                          _pickedImagePath == 'DELETE_IMAGE'
                              ? 'Batalkan Hapus Gambar'
                              : 'Hapus Gambar Saat Ini',
                          style: TextStyle(
                            color: _pickedImagePath == 'DELETE_IMAGE'
                                ? Colors.blue
                                : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Simpan'),
                  onPressed: () {
                    if (_roomNameController.text.trim().isEmpty) return;
                    _updateRoom(room);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
    _roomNameController.clear();
    _pickedImagePath = null;
    await _loadData();
  }

  Future<void> _updateRoom(Map<String, dynamic> room) async {
    try {
      final String newName = _roomNameController.text.trim();
      final String? oldImageName = room['image'];
      String? newRelativeImagePath = oldImageName;
      if (_pickedImagePath == 'DELETE_IMAGE') {
        if (oldImageName != null) {
          final oldFile = File(
            p.join(widget.objectDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) await oldFile.delete();
        }
        newRelativeImagePath = null;
      } else if (_pickedImagePath != null) {
        final String newPath = _pickedImagePath!;
        if (oldImageName != null) {
          final oldFile = File(
            p.join(widget.objectDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) await oldFile.delete();
        }
        final sourceFile = File(newPath);
        final extension = p.extension(newPath);
        final uniqueFileName =
            'room_${DateTime.now().millisecondsSinceEpoch}$extension';
        final destinationPath = p.join(
          widget.objectDirectory.path,
          uniqueFileName,
        );
        await sourceFile.copy(destinationPath);
        newRelativeImagePath = uniqueFileName;
      }
      setState(() {
        room['name'] = newName;
        room['image'] = newRelativeImagePath;
      });
      await _saveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruangan berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui ruangan: $e')),
        );
    }
  }

  Future<void> _exportRoomImage(Map<String, dynamic> room) async {
    final roomImageName = room['image'];
    if (roomImageName == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruangan ini tidak memiliki gambar.'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    if (AppSettings.exportPath == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atur folder export di Pengaturan terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }
    try {
      final sourceFile = File(
        p.join(widget.objectDirectory.path, roomImageName),
      );
      if (!await sourceFile.exists()) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File gambar tidak ditemukan.'),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }
      final roomName = room['name'] ?? 'tanpa_nama';
      final extension = p.extension(roomImageName);
      final now = DateTime.now();
      final fileName =
          'objroom_${roomName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}$extension';
      final destinationPath = p.join(AppSettings.exportPath!, fileName);
      await sourceFile.copy(destinationPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gambar ruangan berhasil diexport ke: $destinationPath',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export gambar ruangan: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ruangan'),
        content: Text('Hapus ruangan "${room['name']}" dan navigasi terkait?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (didConfirm != true) return;
    if (room['image'] != null) {
      final f = File(p.join(widget.objectDirectory.path, room['image']));
      if (await f.exists()) await f.delete();
    }
    setState(() {
      _rooms.removeWhere((r) => r['id'] == room['id']);
      for (var r in _rooms) {
        (r['connections'] as List).removeWhere(
          (c) => c['targetRoomId'] == room['id'],
        );
      }
    });
    await _saveData();
  }

  Future<void> _handleDeleteNavigation(
    Map<String, dynamic> fromRoom,
    Map<String, dynamic> conn,
    Function setDialogState,
  ) async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Navigasi'),
        content: Text('Hapus navigasi "${conn['label'] ?? 'Tanpa Label'}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (didConfirm != true) return;
    final String targetRoomId = conn['targetRoomId'];
    Map<String, dynamic>? targetRoom;
    Map<String, dynamic>? returnConnection;
    try {
      targetRoom = _rooms.firstWhere(
        (r) => r['id'] == targetRoomId,
        orElse: () => null,
      );
      if (targetRoom != null) {
        returnConnection = (targetRoom['connections'] as List? ?? [])
            .firstWhere(
              (c) => c['targetRoomId'] == fromRoom['id'],
              orElse: () => null,
            );
      }
    } catch (_) {}
    if (returnConnection != null) {
      final bool? deleteReturn = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Navigasi Terkait'),
          content: Text(
            'Ruangan "${targetRoom!['name']}" memiliki navigasi kembali. Hapus juga?',
          ),
          actions: [
            TextButton(
              child: const Text('Tidak'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ya, Hapus'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );
      if (deleteReturn == true) {
        (targetRoom!['connections'] as List).remove(returnConnection);
      }
    }
    setDialogState(() {
      (fromRoom['connections'] as List).remove(conn);
    });
    await _saveData();
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigasi berhasil dihapus')),
      );
  }

  // --- MODIFIED NAVIGATION DIALOG ---
  Future<void> _showNavigationDialog(Map<String, dynamic> fromRoom) async {
    final otherRooms = _rooms.where((r) => r['id'] != fromRoom['id']).toList();
    final connections = (fromRoom['connections'] as List? ?? []);
    final labelController = TextEditingController();
    String? selectedTargetRoomId;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Navigasi: ${fromRoom['name']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Navigasi Saat Ini:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (connections.isEmpty) const Text('Belum ada navigasi.'),
                    ...connections.map((conn) {
                      final targetName = _rooms.firstWhere(
                        (r) => r['id'] == conn['targetRoomId'],
                        orElse: () => {'name': '?'},
                      )['name'];
                      return ListTile(
                        title: Text("${conn['label']} -> $targetName"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- TOMBOL EDIT LABEL BARU ---
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () async {
                                await _showEditLabelDialog(conn);
                                setDialogState(() {}); // Refresh
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _handleDeleteNavigation(
                                  fromRoom,
                                  conn,
                                  setDialogState,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    const Text(
                      'Tambah Navigasi Baru:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label Tombol (Kosongkan = Nama Ruangan)',
                      ),
                    ),
                    DropdownButton<String>(
                      hint: const Text('Pilih Ruangan Tujuan'),
                      value: selectedTargetRoomId,
                      isExpanded: true,
                      items: otherRooms
                          .map(
                            (r) => DropdownMenuItem(
                              value: r['id'].toString(),
                              child: Text(r['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedTargetRoomId = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Selesai'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedTargetRoomId == null) return;
                  Map<String, dynamic> targetRoom;
                  String targetRoomName;
                  try {
                    targetRoom = _rooms.firstWhere(
                      (r) => r['id'] == selectedTargetRoomId,
                    );
                    targetRoomName = targetRoom['name'] ?? 'Ruangan';
                  } catch (e) {
                    return;
                  }

                  // LOGIKA LABEL DEFAULT SUDAH BENAR DI SINI
                  String label = labelController.text.trim();
                  if (label.isEmpty) {
                    label = targetRoomName;
                  }

                  final newConnection = {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'label': label,
                    'targetRoomId': selectedTargetRoomId,
                  };
                  setDialogState(() {
                    connections.add(newConnection);
                  });
                  await _saveData();
                  labelController.clear();
                  selectedTargetRoomId = null;

                  final bool? createReturn = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Navigasi Balik Otomatis'),
                      content: Text(
                        'Buat navigasi balik dari "$targetRoomName" kembali ke "${fromRoom['name']}"?',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Tidak'),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        ElevatedButton(
                          child: const Text('Ya, Buat'),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (createReturn == true) {
                    try {
                      targetRoom['connections'] ??= [];
                      final returnConnection = {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'label': fromRoom['name'] ?? 'Ruangan Awal',
                        'targetRoomId': fromRoom['id'],
                      };
                      (targetRoom['connections'] as List).add(returnConnection);
                      await _saveData();
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Navigasi balik berhasil dibuat.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                    } catch (e) {
                      debugPrint("Gagal buat navigasi balik: $e");
                    }
                  }
                  setDialogState(() {});
                },
                child: const Text('Tambah'),
              ),
            ],
          );
        },
      ),
    );
    setState(() {});
  }

  // --- DIALOG EDIT LABEL BARU ---
  Future<void> _showEditLabelDialog(Map<String, dynamic> connection) async {
    final controller = TextEditingController(text: connection['label']);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Label Tombol'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Label Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                connection['label'] = controller.text.trim();
                await _saveData();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Ruangan Objek'),
        actions: [
          IconButton(
            icon: Icon(_isReorderMode ? Icons.link : Icons.swap_vert),
            tooltip: _isReorderMode
                ? 'Aktifkan Mode Navigasi'
                : 'Aktifkan Mode Pindah',
            onPressed: () {
              setState(() {
                _isReorderMode = !_isReorderMode;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _rooms.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx -= 1;
                  final item = _rooms.removeAt(oldIdx);
                  _rooms.insert(newIdx, item);
                });
                _saveData();
              },
              itemBuilder: (context, index) {
                final room = _rooms[index];
                final roomName = room['name'] ?? 'Tanpa Nama';
                final roomImage = room['image'];

                return ListTile(
                  key: ValueKey(room['id']),
                  leading: roomImage != null
                      ? Image.file(
                          File(p.join(widget.objectDirectory.path, roomImage)),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(roomName),
                  trailing: _isReorderMode
                      ? ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          ),
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String value) {
                            switch (value) {
                              case 'navigate':
                                _showNavigationDialog(room);
                                break;
                              case 'edit':
                                _showEditRoomDialog(room);
                                break;
                              case 'export_room_image':
                                _exportRoomImage(room);
                                break;
                              case 'delete':
                                _deleteRoom(room);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'navigate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.link, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Atur Navigasi'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Ubah Info (Nama/Foto)'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'export_room_image',
                                  enabled: roomImage != null,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.ios_share,
                                        color: Colors.indigo,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        roomImage != null
                                            ? 'Export Gambar Ruangan'
                                            : 'Tidak Ada Gambar',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Hapus Ruangan',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                );
              },
            ),
    );
  }
}
