// lib/features/building/presentation/viewer/building_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart'; // Import AppSettings
// --- BARU: Import RoomEditorPage ---
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';

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

  String? _selectedConnectionTargetId;

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
      _selectedConnectionTargetId = null;
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
        _currentRoom = _rooms[0];
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

  void _navigateToRoom(String targetRoomId) {
    try {
      final targetRoom = _rooms.firstWhere((r) => r['id'] == targetRoomId);
      setState(() {
        _currentRoom = targetRoom;
        _selectedConnectionTargetId = null; // Reset pilihan dropdown
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruangan tujuan tidak ditemukan!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Fungsi Navigasi ke Editor Ruangan ---
  void _navigateToRoomEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RoomEditorPage(buildingDirectory: widget.buildingDirectory),
      ),
    );
  }

  // --- Fungsi Export Gambar Ruangan ---
  Future<void> _exportCurrentRoomImage() async {
    if (_currentRoom == null) return;

    final roomImageName = _currentRoom!['image'];
    if (roomImageName == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruangan ini tidak memiliki gambar untuk diexport.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (AppSettings.exportPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atur folder export di Pengaturan terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final sourceFile = File(
        p.join(widget.buildingDirectory.path, roomImageName),
      );

      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File gambar tidak ditemukan.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final roomName = _currentRoom!['name'] ?? 'tanpa_nama';
      final extension = p.extension(roomImageName);
      final now = DateTime.now();
      final fileName =
          'room_${roomName}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}${extension}';

      final destinationPath = p.join(AppSettings.exportPath!, fileName);
      await sourceFile.copy(destinationPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gambar ruangan berhasil diexport ke: ${destinationPath}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export gambar ruangan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // --- SELESAI Fungsi Export Gambar Ruangan ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(widget.buildingDirectory.path)),
        // --- PERUBAHAN: Menambahkan opsi ke Editor ---
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'export_room_image') {
                _exportCurrentRoomImage();
              } else if (value == 'edit_room_page') {
                _navigateToRoomEditor();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // Opsi Edit Ruangan
              const PopupMenuItem<String>(
                value: 'edit_room_page',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Buka Editor Ruangan'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // Opsi Export
              PopupMenuItem<String>(
                value: 'export_room_image',
                enabled: _currentRoom != null && _currentRoom!['image'] != null,
                child: Row(
                  children: [
                    const Icon(Icons.ios_share),
                    const SizedBox(width: 8),
                    Text(
                      _currentRoom != null && _currentRoom!['image'] != null
                          ? 'Export Gambar Ruangan'
                          : 'Tidak Ada Gambar',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        // --- SELESAI PERUBAHAN ---
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_currentRoom == null) {
      return const Center(child: Text('Tidak ada ruangan untuk ditampilkan.'));
    }

    return _buildRoomViewer(_currentRoom!);
  }

  Widget _buildRoomViewer(Map<String, dynamic> room) {
    final roomName = room['name'] ?? 'Tanpa Nama';
    final roomImage = room['image'];
    final connections = (room['connections'] as List? ?? []);

    Widget imageWidget;
    if (roomImage != null) {
      final imageFile = File(p.join(widget.buildingDirectory.path, roomImage));
      imageWidget = Image.file(
        imageFile,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 100,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.sensor_door, size: 100, color: Colors.grey),
      );
    }

    // Tentukan item dropdown
    List<DropdownMenuItem<String>> dropdownItems = connections
        .map<DropdownMenuItem<String>>((conn) {
          final String label = conn['label'] ?? 'Pindah';
          final String targetRoomId = conn['targetRoomId'];
          return DropdownMenuItem<String>(
            value: targetRoomId,
            child: Text(label),
          );
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            // DIUBAH: Widget AspectRatio dihapus dari sini.
            child: Container(
              color: Colors.black12,
              // InteractiveViewer sekarang akan mengisi ruang Expanded
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: imageWidget,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(roomName, style: Theme.of(context).textTheme.headlineMedium),
              const Divider(height: 24.0),
              Text('Pintu:', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8.0),
              if (connections.isEmpty)
                const Text('Tidak ada navigasi dari ruangan ini.'),
              if (connections.isNotEmpty)
                DropdownButton<String>(
                  hint: const Text('Pilih ruangan untuk dijelajahi'),
                  isExpanded: true,
                  items: dropdownItems,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _navigateToRoom(newValue);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
