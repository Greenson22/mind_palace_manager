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
  late String _currentRegionPinShape;
  late double _currentRegionOutlineWidth;
  late double _currentRegionShapeStrokeWidth;
  late bool _currentShowRegionDistrictNames;

  // --- BARU: State Warna ---
  late Color _currentRegionPinColor;
  late Color _currentRegionOutlineColor;
  late Color _currentRegionNameColor;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
    _currentMapPinShape = AppSettings.mapPinShape;
    _currentListIconShape = AppSettings.listIconShape;
    _currentShowRegionOutline = AppSettings.showRegionPinOutline;
    _currentRegionPinShape = AppSettings.regionPinShape;
    _currentRegionOutlineWidth = AppSettings.regionPinOutlineWidth;
    _currentRegionShapeStrokeWidth = AppSettings.regionPinShapeStrokeWidth;
    _currentShowRegionDistrictNames = AppSettings.showRegionDistrictNames;

    // --- BARU ---
    _currentRegionPinColor = Color(AppSettings.regionPinColor);
    _currentRegionOutlineColor = Color(AppSettings.regionOutlineColor);
    _currentRegionNameColor = Color(AppSettings.regionNameColor);
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

  // --- BARU: Helper Dialog Color Picker ---
  void _showColorPickerDialog(
    String title,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      Colors.white,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        if (color.value == currentColor.value)
                          const BoxShadow(
                            color: Colors.black45,
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: color.value == currentColor.value
                        ? const Icon(Icons.check, color: Colors.grey)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ... (Bagian Folder Utama tetap sama)
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
            Text(
              'Tampilan Peta Distrik (Bangunan)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            ListTile(
              title: const Text('Bentuk Pin Bangunan'),
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
            Text(
              'Tampilan Peta Wilayah (Distrik)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),

            ListTile(
              title: const Text('Bentuk Pin Distrik'),
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

            if (_currentRegionPinShape != 'Tidak Ada (Tanpa Latar)') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ketebalan Bentuk: ${_currentRegionShapeStrokeWidth.toStringAsFixed(1)}',
                    ),
                    Slider(
                      value: _currentRegionShapeStrokeWidth,
                      min: 0.0,
                      max: 10.0,
                      divisions: 20,
                      label: _currentRegionShapeStrokeWidth.toStringAsFixed(1),
                      onChanged: (val) async {
                        setState(() => _currentRegionShapeStrokeWidth = val);
                        await AppSettings.saveRegionPinShapeStrokeWidth(val);
                      },
                    ),
                  ],
                ),
              ),
              // --- BARU: Pemilih Warna Pin ---
              ListTile(
                title: const Text('Warna Pin Distrik'),
                trailing: GestureDetector(
                  onTap: () => _showColorPickerDialog(
                    'Pilih Warna Pin',
                    _currentRegionPinColor,
                    (color) async {
                      setState(() => _currentRegionPinColor = color);
                      await AppSettings.saveRegionPinColor(color.value);
                    },
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _currentRegionPinColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],

            SwitchListTile(
              title: const Text('Outline Ikon Distrik'),
              subtitle: const Text('Garis tepi luar.'),
              value: _currentShowRegionOutline,
              onChanged: (bool value) async {
                await AppSettings.saveShowRegionPinOutline(value);
                setState(() => _currentShowRegionOutline = value);
              },
            ),

            if (_currentShowRegionOutline) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ketebalan Outline: ${_currentRegionOutlineWidth.toStringAsFixed(1)}',
                    ),
                    Slider(
                      value: _currentRegionOutlineWidth,
                      min: 1.0,
                      max: 6.0,
                      divisions: 10,
                      label: _currentRegionOutlineWidth.toStringAsFixed(1),
                      onChanged: (val) async {
                        setState(() => _currentRegionOutlineWidth = val);
                        await AppSettings.saveRegionPinOutlineWidth(val);
                      },
                    ),
                  ],
                ),
              ),
              // --- BARU: Pemilih Warna Outline ---
              ListTile(
                title: const Text('Warna Outline'),
                trailing: GestureDetector(
                  onTap: () => _showColorPickerDialog(
                    'Pilih Warna Outline',
                    _currentRegionOutlineColor,
                    (color) async {
                      setState(() => _currentRegionOutlineColor = color);
                      await AppSettings.saveRegionOutlineColor(color.value);
                    },
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _currentRegionOutlineColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],

            SwitchListTile(
              title: const Text('Tampilkan Nama Distrik'),
              value: _currentShowRegionDistrictNames,
              onChanged: (bool value) async {
                await AppSettings.saveShowRegionDistrictNames(value);
                setState(() => _currentShowRegionDistrictNames = value);
              },
            ),

            if (_currentShowRegionDistrictNames)
              // --- BARU: Pemilih Warna Nama ---
              ListTile(
                title: const Text('Warna Teks Nama'),
                trailing: GestureDetector(
                  onTap: () => _showColorPickerDialog(
                    'Pilih Warna Teks',
                    _currentRegionNameColor,
                    (color) async {
                      setState(() => _currentRegionNameColor = color);
                      await AppSettings.saveRegionNameColor(color.value);
                    },
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _currentRegionNameColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
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
