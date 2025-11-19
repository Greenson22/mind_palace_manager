// lib/features/building/presentation/viewer/building_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
// Import Halaman Objek Rekursif (Pastikan file ini sudah dibuat sesuai jawaban sebelumnya)
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
  bool _isObjectEditMode = false; // Mode menaruh objek
  List<dynamic> _roomObjects = []; // Daftar objek yang ditaruh di ruangan ini
  File? _roomObjectsJsonFile; // File penyimpanan data objek
  Directory? _roomObjectsRootDir; // Folder root objek untuk ruangan ini
  Offset? _tappedCoords; // Koordinat tap saat mode edit

  List<dynamic> get _rooms => _buildingData['rooms'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.buildingDirectory.path, 'data.json'));
    _loadData();
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
        // Pertahankan ruangan saat ini jika ada (berguna saat refresh)
        if (_currentRoom != null) {
          final found = _rooms.firstWhere(
            (r) => r['id'] == _currentRoom!['id'],
            orElse: () => null,
          );
          _currentRoom = found ?? _rooms[0];
        } else {
          _currentRoom = _rooms[0];
        }

        // --- BARU: Muat objek-objek untuk ruangan yang aktif ---
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
    // Struktur folder: building/room_objects/{roomId}/object_data.json
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
      // Inisialisasi file baru jika belum ada
      await _saveRoomObjects();
    }
  }

  Future<void> _saveRoomObjects() async {
    if (_roomObjectsJsonFile == null) return;

    final data = {
      "view_mode": "root", // Root level (ruangan) dianggap container
      "children": _roomObjects,
    };

    await _roomObjectsJsonFile!.writeAsString(json.encode(data));
  }

  // --- LOGIKA MENAMBAH OBJEK BARU ---

  Future<void> _showAddObjectDialog() async {
    if (_tappedCoords == null) return;

    final nameController = TextEditingController();
    String selectedType = 'mapContainer'; // Default: Tipe Distrik

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
                    'Pilih Tipe Tampilan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Seperti Distrik (Wadah)'),
                    subtitle: const Text(
                      'Cocok untuk lemari, laci, kotak. Menggunakan Pin.',
                    ),
                    value: 'mapContainer',
                    groupValue: selectedType,
                    onChanged: (val) =>
                        setDialogState(() => selectedType = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Seperti Ruangan (Lokasi)'),
                    subtitle: const Text(
                      'Cocok untuk masuk ke dunia lain. Menggunakan Navigasi.',
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

    // 1. Buat ID unik (folder name)
    final folderId = 'obj_${DateTime.now().millisecondsSinceEpoch}';
    final childDir = Directory(p.join(_roomObjectsRootDir!.path, folderId));
    await childDir.create();

    // 2. Buat data awal untuk objek tersebut sesuai Tipe yang dipilih
    final childJsonFile = File(p.join(childDir.path, 'object_data.json'));
    await childJsonFile.writeAsString(
      json.encode({
        "view_mode": viewMode, // <-- Tipe disimpan di sini
        "image_path": null,
        "children": [],
      }),
    );

    // 3. Tambahkan ke daftar objek ruangan ini
    final newObject = {
      "id": folderId,
      "name": name,
      "x": _tappedCoords!.dx,
      "y": _tappedCoords!.dy,
      "type": viewMode, // Simpan tipe juga di parent untuk referensi ikon
    };

    setState(() {
      _roomObjects.add(newObject);
      _tappedCoords = null; // Reset tap
    });

    await _saveRoomObjects();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Objek "$name" berhasil dibuat.')));
    }
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
      // Hapus folder
      final childDir = Directory(p.join(_roomObjectsRootDir!.path, obj['id']));
      if (await childDir.exists()) {
        await childDir.delete(recursive: true);
      }
      // Hapus dari list
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
        _isObjectEditMode = false; // Matikan edit mode saat pindah ruangan
      });
      // Muat objek untuk ruangan baru
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

  void _enterObject(Map<String, dynamic> obj) {
    if (_isObjectEditMode) return; // Jangan masuk jika sedang mode edit

    final childDir = Directory(p.join(_roomObjectsRootDir!.path, obj['id']));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecursiveObjectPage(
          objectDirectory: childDir,
          objectName: obj['name'],
        ),
      ),
    ).then((_) => _loadData()); // Refresh saat kembali
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
            icon: Icon(
              _isObjectEditMode ? Icons.done : Icons.add_circle_outline,
            ),
            tooltip: _isObjectEditMode
                ? 'Selesai Menaruh Objek'
                : 'Taruh Objek',
            color: _isObjectEditMode ? Colors.green : null,
            onPressed: () {
              setState(() {
                _isObjectEditMode = !_isObjectEditMode;
                _tappedCoords = null; // Reset coords saat toggle
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isObjectEditMode
                        ? 'Ketuk pada gambar untuk menaruh objek'
                        : 'Mode lihat aktif',
                  ),
                  duration: const Duration(seconds: 1),
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

    // Widget Stack Utama
    return Column(
      children: [
        // Area Gambar Interaktif + Objek Overlay
        Expanded(
          child: Container(
            color: Colors.black12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    // AspectRatio dihapus agar InteractiveViewer menghandle ukuran
                    // Kita pakai Stack untuk menumpuk Pin di atas Gambar
                    child: Stack(
                      children: [
                        // 1. GAMBAR RUANGAN + DETECTOR TAP
                        GestureDetector(
                          onTapDown: (details) {
                            if (_isObjectEditMode) {
                              // Hitung koordinat relatif terhadap ukuran gambar yang dirender
                              // Karena Image.file menggunakan BoxFit.contain, kita perlu trik sedikit
                              // atau sederhananya, asumsikan stack ini membungkus gambar pas.
                              // Untuk akurasi tinggi, Image harus di-wrap LayoutBuilder.

                              final RenderBox box =
                                  context.findRenderObject() as RenderBox;
                              // Namun, karena struktur widget yang kompleks, cara termudah adalah
                              // mendapatkan posisi relatif terhadap parent Stack ini.

                              // Sederhananya kita pakai localPosition dari constraints parent jika gambar fit cover/contain
                              // Di sini kita pakai ukuran constraints yang diteruskan Image.

                              // FIX: Agar akurat, kita gunakan width/height dari constraints
                              // Asumsi gambar memenuhi lebar/tinggi (fit contain)

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

                        // 2. PIN OBJEK (Render Objek)
                        ..._roomObjects.map((obj) {
                          final double x = obj['x'] ?? 0.5;
                          final double y = obj['y'] ?? 0.5;
                          final String type = obj['type'] ?? 'mapContainer';

                          // Ikon berbeda berdasarkan tipe
                          final IconData icon = type == 'mapContainer'
                              ? Icons
                                    .inbox // Kotak
                              : Icons.touch_app; // Jari/Lokasi
                          final Color color = type == 'mapContainer'
                              ? Colors.blue
                              : Colors.orange;

                          return Positioned(
                            left: x * constraints.maxWidth - 20, // Center
                            top: y * constraints.maxHeight - 20,
                            child: GestureDetector(
                              onTap: () => _enterObject(obj),
                              onLongPress: _isObjectEditMode
                                  ? () => _deleteObject(obj)
                                  : null,
                              child: Tooltip(
                                message: obj['name'],
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.8),
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
                                      ),
                                      child: Icon(
                                        icon,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
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
                                          obj['name'],
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

                        // 3. INDIKATOR TAP (Edit Mode)
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

        // Panel Bawah: Navigasi Ruangan (Tetap Ada)
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
}
