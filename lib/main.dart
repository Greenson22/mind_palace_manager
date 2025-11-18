import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Halaman utama aplikasi sekarang adalah DashboardPage
      home: DashboardPage(),
    );
  }
}

// -------------------------------------
// HALAMAN DASHBOARD (BARU)
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
            // Tombol ke Halaman View (BuildingViewPage)
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

            // Tombol ke Halaman Editor
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

            // Tombol ke Halaman Pengaturan
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
// HALAMAN VIEW (DARI SEBELUMNYA)
// -------------------------------------
class BuildingViewPage extends StatelessWidget {
  const BuildingViewPage({super.key});

  final String longDescription =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
      "Sed euismod, nisl eget aliquam ultricies, nunc nisl ultricies "
      "nunc, quis aliquam nisl nisl sit amet nisl. Sed euismod, nisl "
      // ... (sisa deskripsi panjang) ...
      "Donec eu libero sit amet quam egestas semper. Aenean "
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
// HALAMAN EDITOR (BARU)
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
// HALAMAN PENGATURAN (BARU)
// -------------------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Controller untuk mengelola input teks
  late TextEditingController _folderController;
  // Menyimpan path folder saat ini
  String _currentFolderPath = '/storage/emulated/0/MyAppFolder';

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan nilai saat ini
    _folderController = TextEditingController(text: _currentFolderPath);
  }

  @override
  void dispose() {
    // Selalu dispose controller saat widget dihapus
    _folderController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan pengaturan baru
  void _saveSettings() {
    setState(() {
      _currentFolderPath = _folderController.text;
    });

    // Tampilkan pesan konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lokasi baru disimpan: $_currentFolderPath')),
    );
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
            // TextField untuk memasukkan path folder
            TextField(
              controller: _folderController,
              decoration: const InputDecoration(
                labelText: 'Path Folder',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            // Tombol untuk menyimpan
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
