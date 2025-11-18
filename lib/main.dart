import 'package:flutter/material.dart';

// -------------------------------------
// IMPORT BARU YANG DIPERLUKAN (Tanpa Permission Handler)
// -------------------------------------
import 'package:file_picker/file_picker.dart'; // Untuk memilih folder
import 'package:path/path.dart' as p; // Untuk menggabung path
import 'dart:io'; // Untuk membuat Directory
// (Kita HAPUS 'package:permission_handler/permission_handler.dart')

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
// HALAMAN EDITOR (Sama seperti sebelumnya)
// -------------------------------------
class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Editor')),
      body: const Center(child: Text('Ini adalah halaman untuk mengedit.')),
    );
  }
}

// -------------------------------------
// HALAMAN PENGATURAN (Disesuaikan untuk Linux)
// -------------------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Controller untuk menampilkan path yang dipilih
  late TextEditingController _folderController;
  // Menyimpan path folder utama
  String _currentFolderPath = 'Belum diatur';

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan nilai saat ini
    _folderController = TextEditingController(text: _currentFolderPath);
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  // --- FUNGSI YANG DIPERBARUI (TANPA IZIN) ---
  Future<void> _pickAndCreateFolder() async {
    // 1. Logika izin DIHAPUS. Kita langsung ke langkah 2.

    // 2. Buka dialog 'pilih folder'
    String? selectedPath = await FilePicker.platform.getDirectoryPath();

    if (selectedPath != null) {
      // 3. Jika user memilih path, buat folder 'buildings' di dalamnya
      try {
        // Menggunakan package 'path' (p) untuk menggabungkan path
        final buildingsPath = p.join(selectedPath, 'buildings');

        // Menggunakan 'dart:io' untuk membuat folder
        final buildingsDir = Directory(buildingsPath);
        await buildingsDir.create(recursive: true);

        // 4. Update UI untuk menampilkan path yang baru dipilih
        setState(() {
          _currentFolderPath = selectedPath;
          _folderController.text = _currentFolderPath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Folder "buildings" berhasil dibuat di: $_currentFolderPath',
            ),
          ),
        );
      } catch (e) {
        // Tangani jika ada error saat membuat folder
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat folder: $e')));
      }
    } else {
      // User membatalkan pemilihan folder
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
              readOnly: true, // Dibuat 'read-only'
              decoration: const InputDecoration(
                labelText: 'Path Folder Utama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // Tombol ini sekarang memanggil fungsi _pickAndCreateFolder yang lebih sederhana
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
