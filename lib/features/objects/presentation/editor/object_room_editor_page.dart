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

  // Mode urutkan ruangan
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
      // Pastikan array rooms ada
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

  // --- CRUD RUANGAN ---

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

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    // Hapus file gambar
    if (room['image'] != null) {
      final f = File(p.join(widget.objectDirectory.path, room['image']));
      if (await f.exists()) await f.delete();
    }

    setState(() {
      _rooms.removeWhere((r) => r['id'] == room['id']);
      // Hapus koneksi terkait
      for (var r in _rooms) {
        (r['connections'] as List).removeWhere(
          (c) => c['targetRoomId'] == room['id'],
        );
      }
    });
    await _saveData();
  }

  // --- NAVIGASI (CONNECTION) EDITOR ---
  // (Logika disederhanakan dari RoomEditorPage asli untuk efisiensi tempat, tapi fungsinya sama)
  Future<void> _showNavigationDialog(Map<String, dynamic> room) async {
    final otherRooms = _rooms.where((r) => r['id'] != room['id']).toList();
    String? selectedTarget;
    final labelCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setStateDiag) {
          final connections = room['connections'] as List;
          return AlertDialog(
            title: Text('Navigasi: ${room['name']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // List Koneksi Ada
                  ...connections.map((conn) {
                    final targetName = _rooms.firstWhere(
                      (r) => r['id'] == conn['targetRoomId'],
                      orElse: () => {'name': '?'},
                    )['name'];
                    return ListTile(
                      title: Text("${conn['label']} -> $targetName"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setStateDiag(() => connections.remove(conn));
                          _saveData();
                        },
                      ),
                    );
                  }),
                  const Divider(),
                  // Tambah Baru
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Label Pintu/Arah',
                    ),
                  ),
                  DropdownButton<String>(
                    hint: const Text('Pilih Tujuan'),
                    value: selectedTarget,
                    isExpanded: true,
                    items: otherRooms
                        .map(
                          (r) => DropdownMenuItem(
                            value: r['id'].toString(),
                            child: Text(r['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setStateDiag(() => selectedTarget = v),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedTarget != null) {
                        connections.add({
                          'id': DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          'label': labelCtrl.text.isEmpty
                              ? 'Masuk'
                              : labelCtrl.text,
                          'targetRoomId': selectedTarget,
                        });
                        labelCtrl.clear();
                        selectedTarget = null;
                        _saveData();
                        setStateDiag(() {});
                      }
                    },
                    child: const Text('Tambah Koneksi'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      ),
    );
    setState(() {}); // Refresh UI utama
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Ruangan Objek'),
        actions: [
          IconButton(
            icon: Icon(_isReorderMode ? Icons.check : Icons.swap_vert),
            onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
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
              buildDefaultDragHandles: _isReorderMode,
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
                return ListTile(
                  key: ValueKey(room['id']),
                  leading: room['image'] != null
                      ? Image.file(
                          File(
                            p.join(widget.objectDirectory.path, room['image']),
                          ),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(room['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.link),
                        onPressed: () => _showNavigationDialog(room),
                        tooltip: 'Atur Navigasi',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRoom(room),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
