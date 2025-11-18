import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert'; // <-- IMPORT BARU untuk JSON

// -------------------------------------
// KELAS STATIS BARU (Untuk Berbagi Path)
// -------------------------------------
/// Menyimpan pengaturan global (path) agar bisa diakses
/// oleh SettingsPage dan EditorPage.
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
                    builder: (context) => const BuildingViewPage(),
                  ),
                );
              },
              child: const Text('Buka Halaman View'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditorPage()),
                );
              },
              child: const Text('Buka Halaman Editor'),
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
// HALAMAN VIEW (Sama seperti sebelumnya)
// -------------------------------------
class BuildingViewPage extends StatelessWidget {
  const BuildingViewPage({super.key});

  final String longDescription =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
      "Sed euismod, nisl eget aliquam ultricies, nunc nisl ultricies "
      // ... (sisa deskripsi panjang) ...
      "ultricies mi vitae est. Mauris placerat eleifend leo.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tampilan Bangunan')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                'https://via.placeholder.com/600x400.png?text=Gambar+Bangunan',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Deskripsi Bangunan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              Text(
                longDescription,
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.arrow_back),
            ),
            FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------
// HALAMAN EDITOR (DIMODIFIKASI TOTAL)
// Menjadi halaman untuk me-list dan membuat bangunan
// -------------------------------------
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  List<Directory> _buildingFolders = [];
  bool _isLoading = false;
  final TextEditingController _newBuildingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Kita panggil 'load' saat halaman dibuka,
    // tapi kita butuh context untuk SnackBar, jadi kita tunda sedikit.
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

    // 1. Cek apakah path utama sudah diatur
    if (AppSettings.baseBuildingsPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Path utama belum diatur. Silakan ke Pengaturan.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 2. Baca semua folder di dalam path utama
    try {
      final buildingsDir = Directory(AppSettings.baseBuildingsPath!);
      // Pastikan folder 'buildings' ada
      if (!await buildingsDir.exists()) {
        await buildingsDir.create(recursive: true);
      }

      final entities = await buildingsDir.list().toList();
      setState(() {
        _buildingFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat bangunan: $e')));
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
      Navigator.of(context).pop(); // Tutup dialog
      _loadBuildings(); // Ini akan memicu pesan error "path belum diatur"
      return;
    }

    final String buildingName = _newBuildingController.text.trim();
    if (buildingName.isEmpty) {
      return; // Jangan lakukan apa-apa jika nama kosong
    }

    try {
      // 1. Buat folder baru
      final newBuildingPath = p.join(
        AppSettings.baseBuildingsPath!,
        buildingName,
      );
      final newDir = Directory(newBuildingPath);
      await newDir.create(recursive: true);

      // 2. Buat file data.json
      final dataJsonFile = File(p.join(newBuildingPath, 'data.json'));
      // Tulis data JSON awal (daftar ruangan kosong)
      await dataJsonFile.writeAsString(json.encode({"rooms": []}));

      Navigator.of(context).pop(); // Tutup dialog
      await _loadBuildings(); // Muat ulang daftar bangunan

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bangunan "$buildingName" berhasil dibuat')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Tutup dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat bangunan: $e')));
    }
  }

  void _navigateToRoomEditor(Directory buildingDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomEditorPage(buildingDirectory: buildingDir),
      ),
    ).then((_) {
      // Muat ulang daftar jika diperlukan (misal, jika ada perubahan)
      // _loadBuildings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Bangunan'),
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
        child: const Icon(Icons.add_business), // Icon yang relevan
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
        final folderName = p.basename(folder.path); // Dapatkan nama folder
        return ListTile(
          leading: const Icon(Icons.location_city, size: 40),
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          onTap: () => _navigateToRoomEditor(folder),
        );
      },
    );
  }
}

// -------------------------------------
// HALAMAN PENGATURAN (DIMODIFIKASI)
// Untuk menyimpan path ke AppSettings
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
    // Inisialisasi controller dengan nilai yang tersimpan (jika ada)
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

        // --- MODIFIKASI PENTING ---
        // Simpan path ke variabel statis
        AppSettings.baseBuildingsPath = buildingsDir.path;

        // Update UI untuk menampilkan path "buildings" yang baru
        setState(() {
          _folderController.text = AppSettings.baseBuildingsPath!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Folder "buildings" berhasil diatur di: ${AppSettings.baseBuildingsPath}',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat folder: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemilihan folder dibatalkan')),
      );
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
                labelText: 'Path Folder "buildings"', // Label diubah
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
// HALAMAN BARU (RoomEditorPage)
// Halaman untuk mengelola ruangan di dalam satu bangunan
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

  // Controller untuk dialog tambah ruangan
  final TextEditingController _roomNameController = TextEditingController();
  String? _pickedImagePath;

  // Helper getter untuk mengakses daftar ruangan
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
        // Jika file tidak ada, buat file dasar
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data ruangan: $e')));
    }
  }

  Future<void> _saveData() async {
    try {
      await _jsonFile.writeAsString(json.encode(_buildingData));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
    }
  }

  Future<void> _showAddRoomDialog() async {
    _roomNameController.clear();
    _pickedImagePath = null;

    // Kita butuh StatefulBuilder agar dialog bisa update saat gambar dipilih
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

      // 1. Jika gambar dipilih, copy ke folder bangunan
      if (_pickedImagePath != null) {
        final sourceFile = File(_pickedImagePath!);
        final imageName = p.basename(_pickedImagePath!);
        final destinationPath = p.join(
          widget.buildingDirectory.path,
          imageName,
        );

        // Copy file
        await sourceFile.copy(destinationPath);
        relativeImagePath = imageName; // Simpan nama filenya saja
      }

      // 2. Buat data ruangan baru
      final newRoom = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': roomName,
        'image': relativeImagePath, // Nama file gambar
        'connections': [], // Tempat untuk navigasi
      };

      // 3. Update state dan simpan ke file
      setState(() {
        _rooms.add(newRoom);
      });
      await _saveData();

      Navigator.of(context).pop(); // Tutup dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruangan "$roomName" berhasil dibuat')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Tutup dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat ruangan: $e')));
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
        child: const Icon(Icons.add_to_home_screen), // Icon yang relevan
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
          // Coba muat gambar dari file lokal
          final imageFile = File(
            p.join(widget.buildingDirectory.path, roomImage),
          );
          leadingIcon = Image.file(
            imageFile,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Jika gagal (file tidak ada), tampilkan placeholder
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
          // Di sini Anda bisa tambahkan tombol untuk mengelola 'connections'
          trailing: IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              // TODO: Tampilkan UI untuk mengedit navigasi (connections)
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
