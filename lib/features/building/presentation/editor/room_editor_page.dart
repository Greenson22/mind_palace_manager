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

  // --- State untuk melacak mode ---
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
        ).showSnackBar(SnackBar(content: Text('Gagal membuat bangunan: $e')));
      }
    }
  }

  // --- MULAI FUNGSI EDIT/HAPUS ---

  Future<void> _showEditRoomDialog(Map<String, dynamic> room) async {
    // Siapkan controller dengan data ruangan saat ini
    _roomNameController.text = room['name'] ?? '';
    _pickedImagePath = null; // Reset path file yang baru dipick

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
                            // Toggle antara null (normal) dan penanda hapus
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

    // Reset controller setelah dialog ditutup
    _roomNameController.clear();
    _pickedImagePath = null;
    await _loadData(); // Muat ulang data untuk refresh UI
  }

  Future<void> _updateRoom(Map<String, dynamic> room) async {
    try {
      final String newName = _roomNameController.text.trim();
      final String? oldImageName = room['image'];
      String? newRelativeImagePath = oldImageName;

      // 1. Tangani Gambar
      if (_pickedImagePath == 'DELETE_IMAGE') {
        // Hapus gambar
        if (oldImageName != null) {
          final oldFile = File(
            p.join(widget.buildingDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
        newRelativeImagePath = null;
      } else if (_pickedImagePath != null) {
        // Ganti gambar
        // Hapus gambar lama (jika ada)
        if (oldImageName != null) {
          final oldFile = File(
            p.join(widget.buildingDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }

        // Salin gambar baru
        final sourceFile = File(_pickedImagePath!);
        final imageName = p.basename(_pickedImagePath!);
        final destinationPath = p.join(
          widget.buildingDirectory.path,
          imageName,
        );

        await sourceFile.copy(destinationPath);
        newRelativeImagePath = imageName;
      }

      // 2. Update data ruangan
      // Gunakan setState di sini untuk mengupdate state lokal sebelum _saveData
      setState(() {
        room['name'] = newName;
        room['image'] = newRelativeImagePath;
      });

      // 3. Simpan
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui ruangan: $e')),
        );
      }
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final String roomId = room['id'];
    final String roomName = room['name'] ?? 'Ruangan Tanpa Nama';

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ruangan'),
        content: Text(
          'Anda yakin ingin menghapus ruangan "$roomName" dan semua koneksi yang mengarah ke/dari ruangan ini?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Permanen'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (didConfirm != true) return;

    try {
      // 1. Hapus file gambar (jika ada)
      final String? imageName = room['image'];
      if (imageName != null) {
        final imageFile = File(
          p.join(widget.buildingDirectory.path, imageName),
        );
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // 2. Hapus ruangan dari list
      setState(() {
        _rooms.removeWhere((r) => r['id'] == roomId);
      });

      // 3. Bersihkan koneksi dari ruangan lain yang mengarah ke ruangan ini
      for (var otherRoom in _rooms) {
        if (otherRoom['connections'] is List) {
          (otherRoom['connections'] as List).removeWhere(
            (conn) => conn['targetRoomId'] == roomId,
          );
        }
      }

      // 4. Simpan perubahan
      await _saveData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ruangan "$roomName" berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus ruangan: $e')));
      }
    }
  }

  // --- SELESAI FUNGSI EDIT/HAPUS ---

  // FUNGSI NAVIGASI LAMA (Hanya perlu dipertahankan)
  Future<void> _handleDeleteNavigation(
    Map<String, dynamic> fromRoom,
    Map<String, dynamic> conn,
    Function setDialogState,
  ) async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Navigasi'),
        content: Text(
          'Anda yakin ingin menghapus navigasi:\n'
          '"${conn['label'] ?? 'Tanpa Label'}"?',
        ),
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

    if (didConfirm != true) {
      return;
    }

    final String targetRoomId = conn['targetRoomId'];
    Map<String, dynamic>? targetRoom;
    Map<String, dynamic>? returnConnection;

    try {
      targetRoom = _rooms.firstWhere((r) => r['id'] == targetRoomId);
      returnConnection = (targetRoom?['connections'] as List? ?? []).firstWhere(
        (c) => c['targetRoomId'] == fromRoom['id'],
      );
    } catch (e) {
      returnConnection = null;
    }

    if (returnConnection != null) {
      final bool? deleteReturn = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Navigasi Terkait'),
          content: Text(
            'Ruangan "${targetRoom!['name']}" memiliki navigasi kembali ("${returnConnection!['label']}") ke ruangan ini.\n\n'
            'Apakah Anda ingin menghapus navigasi kembali tersebut juga?',
          ),
          actions: [
            TextButton(
              child: const Text('Jangan Hapus'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ya, Hapus Keduanya'),
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigasi berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
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
                        Map<String, dynamic> targetRoom;
                        try {
                          targetRoom = otherRooms.firstWhere(
                            (r) => r['id'] == conn['targetRoomId'],
                          );
                        } catch (e) {
                          targetRoom = {'name': 'Ruangan Dihapus'};
                        }

                        return ListTile(
                          title: Text(conn['label'] ?? 'Tanpa Label'),
                          subtitle: Text('-> ${targetRoom['name']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _handleDeleteNavigation(
                                fromRoom,
                                conn,
                                setDialogState,
                              );
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
                          labelText: 'Label Tombol (Kosongkan = Nama Ruangan)',
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
                  onPressed: () async {
                    if (selectedTargetRoomId == null) return;

                    Map<String, dynamic> targetRoom;
                    String targetRoomName;

                    try {
                      targetRoom = otherRooms.firstWhere(
                        (r) => r['id'] == selectedTargetRoomId,
                      );
                      targetRoomName =
                          targetRoom['name'] ?? 'Ruangan Tanpa Nama';
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Ruangan tujuan tidak valid'),
                          ),
                        );
                      }
                      return;
                    }

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

                    String addedLabel = label;
                    labelController.clear();
                    selectedTargetRoomId = null;

                    final bool? createReturn = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Navigasi Balik Otomatis'),
                        content: Text(
                          'Berhasil menambah: "${fromRoom['name']}" -> "$addedLabel" -> "$targetRoomName".\n\n'
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
                        final fullTargetRoom = (_rooms as List).firstWhere(
                          (r) => r['id'] == targetRoom['id'],
                        );

                        fullTargetRoom['connections'] ??= [];

                        final returnConnection = {
                          'id': DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          'label': fromRoom['name'] ?? 'Ruangan Awal',
                          'targetRoomId': fromRoom['id'],
                        };

                        (fullTargetRoom['connections'] as List).add(
                          returnConnection,
                        );

                        await _saveData();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Navigasi balik dari "$targetRoomName" berhasil dibuat.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal membuat navigasi balik: $e'),
                            ),
                          );
                        }
                      }
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
        // --- TAMBAHAN: Tombol Aksi di AppBar ---
        actions: [
          IconButton(
            // Ganti ikon berdasarkan mode
            icon: Icon(_isReorderMode ? Icons.link : Icons.swap_vert),
            tooltip: _isReorderMode
                ? 'Aktifkan Mode Navigasi'
                : 'Aktifkan Mode Pindah (Urutkan)',
            onPressed: () {
              // Toggle mode
              setState(() {
                _isReorderMode = !_isReorderMode;
              });
            },
          ),
        ],
        // --- SELESAI ---
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

    return ReorderableListView.builder(
      // --- TAMBAHAN: Nonaktifkan handle default (long-press) ---
      buildDefaultDragHandles: false,
      // --- SELESAI ---
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
          key: ValueKey(room['id']),
          leading: CircleAvatar(child: leadingIcon, radius: 25),
          title: Text(roomName),
          subtitle: Text('ID: ${room['id']}'),
          // --- PERUBAHAN: Tampilkan ikon berdasarkan mode ---
          trailing: _isReorderMode
              ? ReorderableDragStartListener(
                  // Mode Pindah: Tampilkan Drag Handle
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                )
              : PopupMenuButton<String>(
                  // Mode Navigasi/Opsi: Tampilkan Menu Opsi
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String value) {
                    switch (value) {
                      case 'navigate':
                        _showNavigationDialog(room);
                        break;
                      case 'edit':
                        _showEditRoomDialog(room);
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
          // --- SELESAI PERUBAHAN ---
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final dynamic room = _rooms.removeAt(oldIndex);
          _rooms.insert(newIndex, room);
        });
        _saveData();
      },
    );
  }
}
