// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mind_palace_manager/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _folderController;
  late String _currentMapPinShape;
  late String _currentListIconShape;
  late bool _currentShowRegionOutline;
  // --- BARU ---
  late String _currentRegionPinShape;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
    _currentMapPinShape = AppSettings.mapPinShape;
    _currentListIconShape = AppSettings.listIconShape;
    _currentShowRegionOutline = AppSettings.showRegionPinOutline;
    // --- BARU ---
    _currentRegionPinShape = AppSettings.regionPinShape;
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCreateFolder() async {
    // ... (Kode _pickAndCreateFolder tetap sama)
    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath != null) {
      try {
        final rootDir = Directory(selectedPath);
        await AppSettings.saveBaseBuildingsPath(rootDir.path);
        setState(() {
          _folderController.text = AppSettings.baseBuildingsPath!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Folder utama berhasil diatur: ${AppSettings.baseBuildingsPath}',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal mengatur folder: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
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
                labelText: 'Path Folder Utama (Root)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickAndCreateFolder,
              child: const Text('Pilih Lokasi...'),
            ),
            const Divider(height: 32.0),

            // --- SETTING PETA DISTRIK (Bangunan) ---
            Text(
              'Tampilan Peta Distrik (Bangunan)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            ListTile(
              title: const Text('Bentuk Pin Bangunan'),
              subtitle: const Text('Untuk item di dalam Distrik'),
              trailing: DropdownButton<String>(
                value: _currentMapPinShape,
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    await AppSettings.saveMapPinShape(newValue);
                    setState(() => _currentMapPinShape = newValue);
                  }
                },
                items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
              ),
            ),

            const Divider(height: 32.0),

            // --- SETTING PETA WILAYAH (Distrik) ---
            Text(
              'Tampilan Peta Wilayah (Distrik)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),

            // 1. Pilihan Bentuk
            ListTile(
              title: const Text('Bentuk Pin Distrik'),
              subtitle: const Text('Untuk item di dalam Wilayah'),
              trailing: DropdownButton<String>(
                value: _currentRegionPinShape,
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    await AppSettings.saveRegionPinShape(newValue);
                    setState(() => _currentRegionPinShape = newValue);
                  }
                },
                items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
              ),
            ),

            // 2. Toggle Outline
            SwitchListTile(
              title: const Text('Outline Ikon Distrik'),
              subtitle: const Text(
                'Garis tepi putih agar ikon terlihat jelas (Hanya aktif jika bentuk Bulat/Kotak).',
              ),
              value: _currentShowRegionOutline,
              onChanged: (bool value) async {
                await AppSettings.saveShowRegionPinOutline(value);
                setState(() => _currentShowRegionOutline = value);
              },
            ),

            const Divider(height: 32.0),
            Text(
              'Tampilan Daftar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            ListTile(
              title: const Text('Bentuk Ikon Daftar'),
              trailing: DropdownButton<String>(
                value: _currentListIconShape,
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    await AppSettings.saveListIconShape(newValue);
                    setState(() => _currentListIconShape = newValue);
                  }
                },
                items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
