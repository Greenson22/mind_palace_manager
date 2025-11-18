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
  // --- BARU ---
  late bool _currentShowRegionOutline;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
    _currentMapPinShape = AppSettings.mapPinShape;
    _currentListIconShape = AppSettings.listIconShape;
    // --- BARU ---
    _currentShowRegionOutline = AppSettings.showRegionPinOutline;
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
        final rootDir = Directory(selectedPath);
        await AppSettings.saveBaseBuildingsPath(rootDir.path);

        setState(() {
          _folderController.text = AppSettings.baseBuildingsPath!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Folder utama berhasil diatur di: ${AppSettings.baseBuildingsPath}',
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
            const SizedBox(height: 8.0),
            Text(
              'Ini adalah lokasi utama tempat semua data Anda akan disimpan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const Divider(height: 32.0),
            Text(
              'Tampilan Peta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),

            // --- PENGATURAN BENTUK PIN ---
            ListTile(
              title: const Text('Bentuk Pin Peta (Umum)'),
              subtitle: const Text('Bulat, Kotak, atau Tanpa Latar'),
              trailing: DropdownButton<String>(
                value: _currentMapPinShape,
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    await AppSettings.saveMapPinShape(newValue);
                    setState(() {
                      _currentMapPinShape = newValue;
                    });
                  }
                },
                items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
              ),
            ),

            // --- BARU: TOGGLE OUTLINE WILAYAH ---
            SwitchListTile(
              title: const Text('Outline Ikon Distrik (Peta Wilayah)'),
              subtitle: const Text(
                'Tampilkan garis tepi putih pada ikon distrik di peta wilayah.',
              ),
              value: _currentShowRegionOutline,
              onChanged: (bool value) async {
                await AppSettings.saveShowRegionPinOutline(value);
                setState(() {
                  _currentShowRegionOutline = value;
                });
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
                    setState(() {
                      _currentListIconShape = newValue;
                    });
                  }
                },
                items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
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
