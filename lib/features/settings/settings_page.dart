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

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
    _currentMapPinShape = AppSettings.mapPinShape;
    _currentListIconShape = AppSettings.listIconShape;
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
              'Ini adalah lokasi utama tempat semua distrik dan bangunan Anda akan disimpan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // --- PENGATURAN BENTUK PIN PETA (DIPERBARUI) ---
            const Divider(height: 32.0),
            Text(
              'Tampilan Pin Peta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Atur bentuk pin bangunan di Peta Distrik.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8.0),
            DropdownButton<String>(
              value: _currentMapPinShape,
              isExpanded: true,
              // --- PERUBAHAN DI SINI ---
              items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              // --- SELESAI PERUBAHAN ---
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  await AppSettings.saveMapPinShape(newValue);
                  setState(() {
                    _currentMapPinShape = newValue;
                  });
                }
              },
            ),
            // --- SELESAI DIPERBARUI ---

            // --- Pengaturan Bentuk Ikon Daftar (Tidak Berubah) ---
            const Divider(height: 32.0),
            Text(
              'Tampilan Ikon Daftar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Atur bentuk bingkai (outline) untuk ikon di Daftar Bangunan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8.0),
            DropdownButton<String>(
              value: _currentListIconShape,
              isExpanded: true,
              items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  await AppSettings.saveListIconShape(newValue);
                  setState(() {
                    _currentListIconShape = newValue;
                  });
                }
              },
            ),
            // --- SELESAI ---
          ],
        ),
      ),
    );
  }
}
