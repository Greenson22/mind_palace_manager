// lib/features/building/presentation/viewer/building_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(p.basename(widget.buildingDirectory.path))),
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
        fit: BoxFit.cover,
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black12,
              child: imageWidget,
            ),
            const SizedBox(height: 16.0),
            Text(roomName, style: Theme.of(context).textTheme.headlineMedium),
            const Divider(height: 24.0),
            Text(
              'Pintu Keluar:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            if (connections.isEmpty)
              const Text('Tidak ada navigasi dari ruangan ini.'),
            ...connections.map((conn) {
              final String label = conn['label'] ?? 'Pindah';
              final String targetRoomId = conn['targetRoomId'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app),
                  label: Text(label),
                  onPressed: () => _navigateToRoom(targetRoomId),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
