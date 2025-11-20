// lib/features/building/presentation/editor/room_editor_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';

class RoomEditorPage extends StatefulWidget {
  final Directory buildingDirectory;

  const RoomEditorPage({super.key, required this.buildingDirectory});

  @override
  State<RoomEditorPage> createState() => _RoomEditorPageState();
}

class _RoomEditorPageState extends State<RoomEditorPage> {
  late File _jsonFile;
  Map<String, dynamic> _buildingData = {'rooms': []};
  bool _isLoading = true;
  bool _isReorderMode = false;
  final TextEditingController _roomNameController = TextEditingController();
  String? _pickedImagePath;

  List<dynamic> get _rooms => _buildingData['rooms'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.buildingDirectory.path, 'data.json'));
    _loadData();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (!await _jsonFile.exists()) await _saveData();
      final content = await _jsonFile.readAsString();
      setState(() {
        _buildingData = json.decode(content);
        for (var room in _rooms) {
          room['connections'] ??= [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  Future<void> _saveData() async {
    try {
      await _jsonFile.writeAsString(json.encode(_buildingData));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _showAddRoomDialog() async {
    _roomNameController.clear();
    _pickedImagePath = null;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Ruangan Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Ruangan',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar'),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        if (result != null &&
                            result.files.single.path != null) {
                          setDialogState(
                            () => _pickedImagePath = result.files.single.path!,
                          );
                        }
                      },
                    ),
                    if (_pickedImagePath != null)
                      Text(
                        'Gambar: ${p.basename(_pickedImagePath!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Buat'),
                  onPressed: _createNewRoom,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewRoom() async {
    final String roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) return;
    try {
      String? relativeImagePath;
      if (_pickedImagePath != null) {
        final sourceFile = File(_pickedImagePath!);
        final extension = p.extension(_pickedImagePath!);
        final uniqueFileName =
            'room_${DateTime.now().millisecondsSinceEpoch}$extension';
        final destinationPath = p.join(
          widget.buildingDirectory.path,
          uniqueFileName,
        );
        await sourceFile.copy(destinationPath);
        relativeImagePath = uniqueFileName;
      }
      final newRoom = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': roomName,
        'image': relativeImagePath,
        'connections': [],
      };
      setState(() => _rooms.add(newRoom));
      await _saveData();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ruangan "$roomName" dibuat')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat ruangan: $e')));
      }
    }
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
                  children: [
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Ruangan',
                      ),
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
                          setDialogState(
                            () => _pickedImagePath = result.files.single.path!,
                          );
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        currentImageName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (room['image'] != null)
                      TextButton(
                        onPressed: () => setDialogState(
                          () => _pickedImagePath =
                              _pickedImagePath == 'DELETE_IMAGE'
                              ? null
                              : 'DELETE_IMAGE',
                        ),
                        child: Text(
                          _pickedImagePath == 'DELETE_IMAGE'
                              ? 'Batalkan Hapus'
                              : 'Hapus Gambar',
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
              actions: [
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
            p.join(widget.buildingDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) await oldFile.delete();
        }
        newRelativeImagePath = null;
      } else if (_pickedImagePath != null) {
        if (oldImageName != null) {
          final oldFile = File(
            p.join(widget.buildingDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) await oldFile.delete();
        }
        final sourceFile = File(_pickedImagePath!);
        final extension = p.extension(_pickedImagePath!);
        final uniqueFileName =
            'room_${DateTime.now().millisecondsSinceEpoch}$extension';
        await sourceFile.copy(
          p.join(widget.buildingDirectory.path, uniqueFileName),
        );
        newRelativeImagePath = uniqueFileName;
      }
      setState(() {
        room['name'] = newName;
        room['image'] = newRelativeImagePath;
      });
      await _saveData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruangan diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ruangan'),
        content: Text('Hapus "${room['name']}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      if (room['image'] != null) {
        final f = File(p.join(widget.buildingDirectory.path, room['image']));
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruangan dihapus'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }

  Future<void> _showNavigationDialog(Map<String, dynamic> fromRoom) async {
    final otherRooms = _rooms.where((r) => r['id'] != fromRoom['id']).toList();
    final connections = (fromRoom['connections'] as List? ?? []);
    final labelController = TextEditingController();
    String? selectedTargetRoomId;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Atur Navigasi: ${fromRoom['name']}'),
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
                      if (connections.isEmpty)
                        const Text('Belum ada navigasi.'),
                      ...connections.map((conn) {
                        final targetName = _rooms.firstWhere(
                          (r) => r['id'] == conn['targetRoomId'],
                          orElse: () => {'name': '?'},
                        )['name'];
                        return ListTile(
                          title: Text(
                            "${conn['label'] ?? 'Pintu'} -> $targetName",
                          ),
                          subtitle: const Text(
                            "Posisi & Arah diatur di Viewer (Mode Edit).",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => connections.remove(conn));
                              _saveData();
                              setDialogState(() {});
                            },
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      const Text(
                        'Tambah Navigasi Baru:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        hint: const Text('Pilih Ruangan Tujuan'),
                        value: selectedTargetRoomId,
                        isExpanded: true,
                        items: otherRooms
                            .map(
                              (room) => DropdownMenuItem(
                                value: room['id'].toString(),
                                child: Text(room['name'] ?? '?'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedTargetRoomId = val),
                      ),
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label (Opsional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Tutup'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Tambah'),
                  onPressed: () async {
                    if (selectedTargetRoomId == null) return;

                    final newConnection = {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'label': labelController.text.isEmpty
                          ? 'Pintu'
                          : labelController.text,
                      'targetRoomId': selectedTargetRoomId,
                      'direction': 'up', // Default sementara
                      'x': 0.5, // Default tengah
                      'y': 0.5, // Default tengah
                    };

                    setState(() => connections.add(newConnection));
                    await _saveData();

                    _offerReturnNavigation(fromRoom, selectedTargetRoomId!);

                    labelController.clear();
                    selectedTargetRoomId = null;
                    setDialogState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _offerReturnNavigation(
    Map<String, dynamic> fromRoom,
    String targetId,
  ) async {
    final targetRoom = _rooms.firstWhere((r) => r['id'] == targetId);
    bool? create = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Navigasi Balik'),
        content: Text(
          'Buat pintu balik dari "${targetRoom['name']}" ke "${fromRoom['name']}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Tidak'),
            onPressed: () => Navigator.pop(c, false),
          ),
          ElevatedButton(
            child: const Text('Ya'),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (create == true) {
      targetRoom['connections'] ??= [];
      (targetRoom['connections'] as List).add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'label': fromRoom['name'],
        'targetRoomId': fromRoom['id'],
        'direction': 'down', // Default balik
        'x': 0.5,
        'y': 0.9, // Default bawah
      });
      await _saveData();
    }
  }

  Future<void> _exportRoomImage(Map<String, dynamic> room) async {
    if (room['image'] == null || AppSettings.exportPath == null) return;
    final src = File(p.join(widget.buildingDirectory.path, room['image']));
    if (await src.exists()) {
      final dest = p.join(
        AppSettings.exportPath!,
        'room_export_${p.basename(src.path)}',
      );
      await src.copy(dest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar diexport'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor: ${p.basename(widget.buildingDirectory.path)}'),
        actions: [
          IconButton(
            icon: Icon(_isReorderMode ? Icons.link : Icons.swap_vert),
            tooltip: _isReorderMode ? 'Mode Navigasi' : 'Mode Urutkan',
            onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRoomList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoomList() {
    if (_rooms.isEmpty) return const Center(child: Text('Belum ada ruangan.'));

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final imagePath = room['image'];
        Widget leading = imagePath != null
            ? Image.file(
                File(p.join(widget.buildingDirectory.path, imagePath)),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.sensor_door);

        return ListTile(
          key: ValueKey(room['id']),
          leading: leading,
          title: Text(room['name'] ?? '?'),
          trailing: _isReorderMode
              ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                )
              : PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'nav') _showNavigationDialog(room);
                    if (v == 'edit') _showEditRoomDialog(room);
                    if (v == 'export') _exportRoomImage(room);
                    if (v == 'del') _deleteRoom(room);
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(
                      value: 'nav',
                      child: Text('Atur Navigasi'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Info'),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export Gambar'),
                    ),
                    const PopupMenuItem(
                      value: 'del',
                      child: Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
        );
      },
      onReorder: (oldIdx, newIdx) {
        setState(() {
          if (newIdx > oldIdx) newIdx -= 1;
          final item = _rooms.removeAt(oldIdx);
          _rooms.insert(newIdx, item);
        });
        _saveData();
      },
    );
  }
}
