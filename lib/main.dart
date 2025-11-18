import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert'; // Untuk JSON

// -------------------------------------
// KELAS STATIS (Sama seperti sebelumnya)
// -------------------------------------
/// Menyimpan pengaturan global (path) agar bisa diakses
/// oleh SettingsPage dan halaman manajemen.
class AppSettings {
  /// Path lengkap ke folder 'buildings' (cth: /home/user/Dokumen/buildings)
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
// HALAMAN DASHBOARD (DIMODIFIKASI)
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
            // TOMBOL VIEW DAN EDITOR DIGANTI DENGAN INI
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
            // TOMBOL PENGATURAN TETAP ADA
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
// HALAMAN VIEW (DIHAPUS)
// -------------------------------------
// Halaman BuildingViewPage (yang statis) telah dihapus
// sesuai permintaan.

// -------------------------------------
// HALAMAN EDITOR (DIHAPUS)
// -------------------------------------
// Halaman EditorPage telah dihapus dan digantikan oleh
// BuildingManagementPage di bawah ini.

// -------------------------------------
// HALAMAN BARU (BuildingManagementPage)
// Menggabungkan fungsionalitas list, buat, view, edit, hapus
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
    // Tunda pemuatan hingga frame pertama selesai
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuildings());
  }

  @override
  void dispose() {
    _newBuildingController.dispose();
    super.dispose();
  }

  // --- Fungsi untuk Memuat Daftar Bangunan ---
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

  // --- Fungsi untuk Membuat Bangunan Baru (Dialog) ---
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

  // --- Fungsi untuk Membuat Bangunan Baru (Logika) ---
  Future<void> _createNewBuilding() async {
    if (AppSettings.baseBuildingsPath == null) {
      Navigator.of(context).pop(); // Tutup dialog
      _loadBuildings(); // Ini akan memicu pesan error "path belum diatur"
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

      // Buat file data.json awal
      final dataJsonFile = File(p.join(newBuildingPath, 'data.json'));
      await dataJsonFile.writeAsString(json.encode({"rooms": []}));

      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog
      }
      await _loadBuildings(); // Muat ulang daftar bangunan

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bangunan "$buildingName" berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat bangunan: $e')));
      }
    }
  }

  // --- Fungsi Aksi untuk ListTile ---

  void _viewBuilding(Directory buildingDir) {
    // TODO: Implementasikan halaman "View" yang sesungguhnya.
    // Untuk saat ini, kita bisa tampilkan placeholder
    // atau navigasi ke halaman yang sama dengan "Edit".
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur "View" belum diimplementasikan.')),
    );
    // Alternatif:
    // _editBuilding(buildingDir);
  }

  void _editBuilding(Directory buildingDir) {
    // Navigasi ke halaman editor ruangan (RoomEditorPage)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomEditorPage(buildingDirectory: buildingDir),
      ),
    ).then((_) {
      // Muat ulang daftar jika diperlukan
      // _loadBuildings();
    });
  }

  Future<void> _deleteBuilding(Directory buildingDir) async {
    final buildingName = p.basename(buildingDir.path);

    // Tampilkan dialog konfirmasi
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

    // Jika dikonfirmasi, lakukan penghapusan
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
        await _loadBuildings(); // Muat ulang daftar
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus bangunan: $e')),
          );
        }
      }
    }
  }

  // --- Build Method Utama ---

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

    // Tampilkan daftar bangunan
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
            mainAxisSize: MainAxisSize.min, // Agar Row tidak makan tempat
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: 'Lihat',
                onPressed: () => _viewBuilding(folder),
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
          onTap: null, // Nonaktifkan onTap utama agar tombol bisa diklik
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
// HALAMAN RoomEditorPage (Sama seperti sebelumnya)
// Halaman ini tidak diubah, karena ini adalah tujuan dari tombol "Edit"
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

  List<dynamic> get _rooms => _buildingData['rooms'];

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
        await _saveData();
      }
      final content = await _jsonFile.readAsString();
      setState(() {
        _buildingData = json.decode(content);
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
        'connections': [],
      };

      setState(() {
        _rooms.add(newRoom);
      });
      await _saveData();

      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruangan "$roomName" berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat ruangan: $e')));
      }
    }
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur navigasi belum diimplementasikan.'),
                ),
              );
            },
            tooltip: 'Atur Navigasi',
          ),
        );
      },
    );
  }
}
