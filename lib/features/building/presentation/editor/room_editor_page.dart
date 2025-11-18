// lib/features/building/presentation/editor/room_editor_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';

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
    setState(() {
      _isLoading = true;
    });
    try {
      if (!await _jsonFile.exists()) {
        await _saveData(); // Buat file dasar jika tidak ada
      }
      final content = await _jsonFile.readAsString();
      setState(() {
        _buildingData = json.decode(content);
        // Pastikan setiap ruangan punya list 'connections'
        for (var room in _rooms) {
          room['connections'] ??= [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data ruangan: $e')),
        );
      }
    }
  }

  Future<void> _saveData() async {
    try {
      await _jsonFile.writeAsString(json.encode(_buildingData));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
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
                      label: const Text('Pilih Gambar Isometri'),
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
                    if (_pickedImagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Gambar: ${p.basename(_pickedImagePath!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
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
        final imageName = p.basename(_pickedImagePath!);
        final destinationPath = p.join(
          widget.buildingDirectory.path,
          imageName,
        );

        await sourceFile.copy(destinationPath);
        relativeImagePath = imageName;
      }

      final newRoom = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': roomName,
        'image': relativeImagePath,
        'connections': [], // Selalu buat list kosong
      };

      setState(() {
        _rooms.add(newRoom);
      });
      await _saveData();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruangan "$roomName" berhasil dibuat')),
        );
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
                        final targetRoom = otherRooms.firstWhere(
                          (r) => r['id'] == conn['targetRoomId'],
                          orElse: () => {'name': 'Ruangan Dihapus'},
                        );
                        return ListTile(
                          title: Text(conn['label'] ?? 'Tanpa Label'),
                          subtitle: Text('-> ${targetRoom['name']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                connections.remove(conn);
                              });
                              _saveData(); // Simpan perubahan
                            },
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
                          labelText: 'Label Tombol',
                        ),
                      ),
                      DropdownButton<String>(
                        hint: const Text('Pilih Ruangan Tujuan'),
                        value: selectedTargetRoomId,
                        isExpanded: true,
                        items: otherRooms.map((room) {
                          return DropdownMenuItem(
                            value: room['id'].toString(),
                            child: Text(room['name'] ?? 'Tanpa Nama'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setDialogState(() {
                            selectedTargetRoomId = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Tutup'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Tambah'),
                  onPressed: () {
                    if (labelController.text.isNotEmpty &&
                        selectedTargetRoomId != null) {
                      final newConnection = {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'label': labelController.text,
                        'targetRoomId': selectedTargetRoomId,
                      };
                      setDialogState(() {
                        connections.add(newConnection);
                      });
                      _saveData(); // Simpan perubahan
                      // Reset form
                      labelController.clear();
                      selectedTargetRoomId = null;
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor: ${p.basename(widget.buildingDirectory.path)}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRoomList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        tooltip: 'Tambah Ruangan Baru',
        child: const Icon(Icons.add_to_home_screen),
      ),
    );
  }

  Widget _buildRoomList() {
    if (_rooms.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada ruangan.\nKlik tombol + untuk menambahkannya.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final roomName = room['name'] ?? 'Tanpa Nama';
        final roomImage = room['image'];

        Widget leadingIcon;
        if (roomImage != null) {
          final imageFile = File(
            p.join(widget.buildingDirectory.path, roomImage),
          );
          leadingIcon = Image.file(
            imageFile,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported, size: 40);
            },
          );
        } else {
          leadingIcon = const Icon(Icons.sensor_door, size: 40);
        }

        return ListTile(
          leading: CircleAvatar(child: leadingIcon, radius: 25),
          title: Text(roomName),
          subtitle: Text('ID: ${room['id']}'),
          trailing: IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              _showNavigationDialog(room);
            },
            tooltip: 'Atur Navigasi',
          ),
        );
      },
    );
  }
}
