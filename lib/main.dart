import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert'; // Untuk JSON

// -------------------------------------
// KELAS STATIS (Sama seperti sebelumnya)
// -------------------------------------
class AppSettings {
  static String? baseBuildingsPath;
}

// -------------------------------------
// MAIN & APP (Sama seperti sebelumnya)
// -------------------------------------
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DashboardPage());
  }
}

// -------------------------------------
// HALAMAN DASHBOARD (Sama seperti sebelumnya)
// -------------------------------------
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Utama')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuildingManagementPage(),
                  ),
                );
              },
              child: const Text('Kelola Bangunan'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------
// HALAMAN MANAJEMEN BANGUNAN (DIMODIFIKASI)
// Tombol "View" sekarang berfungsi
// -------------------------------------
class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  List<Directory> _buildingFolders = [];
  bool _isLoading = false;
  final TextEditingController _newBuildingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuildings());
  }

  @override
  void dispose() {
    _newBuildingController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoading = true;
    });

    if (AppSettings.baseBuildingsPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Path utama belum diatur. Silakan ke Pengaturan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final buildingsDir = Directory(AppSettings.baseBuildingsPath!);
      if (!await buildingsDir.exists()) {
        await buildingsDir.create(recursive: true);
      }

      final entities = await buildingsDir.list().toList();
      setState(() {
        _buildingFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat bangunan: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreateBuildingDialog() async {
    _newBuildingController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Bangunan Baru'),
          content: TextField(
            controller: _newBuildingController,
            decoration: const InputDecoration(hintText: 'Nama Bangunan'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Buat'),
              onPressed: _createNewBuilding,
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewBuilding() async {
    if (AppSettings.baseBuildingsPath == null) {
      Navigator.of(context).pop();
      _loadBuildings();
      return;
    }

    final String buildingName = _newBuildingController.text.trim();
    if (buildingName.isEmpty) return;

    try {
      final newBuildingPath = p.join(
        AppSettings.baseBuildingsPath!,
        buildingName,
      );
      final newDir = Directory(newBuildingPath);
      await newDir.create(recursive: true);

      final dataJsonFile = File(p.join(newBuildingPath, 'data.json'));
      await dataJsonFile.writeAsString(json.encode({"rooms": []}));

      if (mounted) {
        Navigator.of(context).pop();
      }
      await _loadBuildings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bangunan "$buildingName" berhasil dibuat')),
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

  // --- MODIFIKASI DI SINI ---
  void _viewBuilding(Directory buildingDir) {
    // Arahkan ke halaman viewer baru
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BuildingViewerPage(buildingDirectory: buildingDir),
      ),
    );
  }

  void _editBuilding(Directory buildingDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomEditorPage(buildingDirectory: buildingDir),
      ),
    );
  }

  Future<void> _deleteBuilding(Directory buildingDir) async {
    final buildingName = p.basename(buildingDir.path);

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Bangunan'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$buildingName"?\n\n'
            'Tindakan ini akan menghapus semua folder, ruangan, dan gambar di dalamnya secara permanen.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      try {
        await buildingDir.delete(recursive: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bangunan "$buildingName" berhasil dihapus.'),
            ),
          );
        }
        await _loadBuildings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus bangunan: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Bangunan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuildings,
            tooltip: 'Muat Ulang Daftar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBuildingDialog,
        tooltip: 'Buat Bangunan Baru',
        child: const Icon(Icons.add_business),
      ),
    );
  }

  Widget _buildBody() {
    if (AppSettings.baseBuildingsPath == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Lokasi folder utama belum diatur.\nSilakan pergi ke "Pengaturan" terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buildingFolders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada bangunan.\nKlik tombol + untuk membuat yang baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _buildingFolders.length,
      itemBuilder: (context, index) {
        final folder = _buildingFolders[index];
        final folderName = p.basename(folder.path);
        return ListTile(
          leading: const Icon(Icons.location_city, size: 40),
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: 'Lihat',
                onPressed: () => _viewBuilding(folder), // <- Diperbarui
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Ruangan',
                onPressed: () => _editBuilding(folder),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Hapus',
                onPressed: () => _deleteBuilding(folder),
              ),
            ],
          ),
          onTap: null,
        );
      },
    );
  }
}

// -------------------------------------
// HALAMAN PENGATURAN (Sama seperti sebelumnya)
// -------------------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _folderController;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCreateFolder() async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath();

    if (selectedPath != null) {
      try {
        final buildingsPath = p.join(selectedPath, 'buildings');
        final buildingsDir = Directory(buildingsPath);
        await buildingsDir.create(recursive: true);

        AppSettings.baseBuildingsPath = buildingsDir.path;

        setState(() {
          _folderController.text = AppSettings.baseBuildingsPath!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Folder "buildings" berhasil diatur di: ${AppSettings.baseBuildingsPath}',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal membuat folder: $e')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilihan folder dibatalkan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atur Lokasi Folder Utama',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _folderController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Path Folder "buildings"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickAndCreateFolder,
              child: const Text('Pilih Lokasi...'),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Folder "buildings" akan otomatis dibuat di dalam lokasi yang Anda pilih.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------
// HALAMAN RoomEditorPage (DIMODIFIKASI)
// Tombol "Atur Navigasi" sekarang berfungsi
// -------------------------------------
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

  // --- FUNGSI BARU UNTUK MENGELOLA NAVIGASI ---
  Future<void> _showNavigationDialog(Map<String, dynamic> fromRoom) async {
    final otherRooms = _rooms.where((r) => r['id'] != fromRoom['id']).toList();
    final connections = (fromRoom['connections'] as List? ?? []);

    final labelController = TextEditingController();
    String? selectedTargetRoomId;

    return showDialog(
      context: context,
      builder: (context) {
        // Gunakan StatefulBuilder agar dialog bisa update
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
  // --- AKHIR FUNGSI BARU ---

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
          // --- MODIFIKASI DI SINI ---
          trailing: IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              // Panggil dialog navigasi baru
              _showNavigationDialog(room);
            },
            tooltip: 'Atur Navigasi',
          ),
        );
      },
    );
  }
}

// -------------------------------------
// HALAMAN BARU (BuildingViewerPage)
// Halaman untuk melihat bangunan dan bernavigasi
// -------------------------------------
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

      // Pastikan semua room punya list 'connections'
      for (var room in _rooms) {
        room['connections'] ??= [];
      }

      if (_rooms.isNotEmpty) {
        // Mulai dari ruangan pertama
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

    // Jika data ada, tampilkan viewer
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
            // Gambar
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black12,
              child: imageWidget,
            ),
            const SizedBox(height: 16.0),
            // Nama Ruangan
            Text(roomName, style: Theme.of(context).textTheme.headlineMedium),
            const Divider(height: 24.0),
            // Navigasi
            Text(
              'Pintu Keluar:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            if (connections.isEmpty)
              const Text('Tidak ada navigasi dari ruangan ini.'),
            // Tampilkan tombol navigasi
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
