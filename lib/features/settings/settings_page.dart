// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/about_page.dart';

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
            const SnackBar(
              content: Text('Folder penyimpanan berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengatur folder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        if (color.value == currentColor.value)
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.4),
                            blurRadius: 8,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 1. Tampilan Umum ---
          _buildSectionHeader('Umum'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.brightness_6, color: primaryColor),
              title: const Text('Tema Aplikasi'),
              subtitle: Text(_getThemeModeLabel(AppSettings.themeMode.value)),
              trailing: DropdownButton<ThemeMode>(
                value: AppSettings.themeMode.value,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    setState(() {
                      AppSettings.saveThemeMode(newValue);
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Sistem'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Terang'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Gelap')),
                ],
              ),
            ),
            const Divider(indent: 56),
            ListTile(
              leading: Icon(Icons.folder_open, color: primaryColor),
              title: const Text('Lokasi Penyimpanan'),
              subtitle: Text(
                _folderController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                // --- PERBAIKAN DI SINI (Ganti Icon) ---
                icon: const Icon(Icons.drive_file_move_outline),
                onPressed: _pickAndCreateFolder,
                tooltip: 'Ubah Folder',
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // --- 2. Visualisasi Peta (Distrik & Bangunan) ---
          _buildSectionHeader('Visualisasi Peta'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.location_city, color: Colors.orange),
              title: const Text('Pin Bangunan'),
              trailing: _buildDropdown(
                value: _currentMapPinShape,
                onChanged: (val) async {
                  if (val != null) {
                    await AppSettings.saveMapPinShape(val);
                    setState(() => _currentMapPinShape = val);
                  }
                },
              ),
            ),
            const Divider(indent: 56),
            ListTile(
              leading: Icon(Icons.map, color: Colors.green),
              title: const Text('Pin Wilayah (Distrik)'),
              trailing: _buildDropdown(
                value: _currentRegionPinShape,
                onChanged: (val) async {
                  if (val != null) {
                    await AppSettings.saveRegionPinShape(val);
                    setState(() => _currentRegionPinShape = val);
                  }
                },
              ),
            ),

            if (_currentRegionPinShape != 'Tidak Ada (Tanpa Latar)') ...[
              const Divider(indent: 56),
              _buildSliderTile(
                icon: Icons.line_weight,
                color: Colors.green,
                title: 'Ketebalan Pin',
                value: _currentRegionShapeStrokeWidth,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                onChanged: (val) async {
                  setState(() => _currentRegionShapeStrokeWidth = val);
                  await AppSettings.saveRegionPinShapeStrokeWidth(val);
                },
              ),
              const Divider(indent: 56),
              ListTile(
                leading: const Icon(Icons.color_lens, color: Colors.green),
                title: const Text('Warna Pin'),
                trailing: _buildColorCircle(
                  _currentRegionPinColor,
                  () => _showColorPickerDialog(
                    'Pilih Warna Pin',
                    _currentRegionPinColor,
                    (c) async {
                      setState(() => _currentRegionPinColor = c);
                      await AppSettings.saveRegionPinColor(c.value);
                    },
                  ),
                ),
              ),
            ],
          ]),

          const SizedBox(height: 24),

          // --- 3. Detail & Outline ---
          _buildSectionHeader('Detail Tampilan'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: Icon(
                Icons.check_circle_outline,
                color: Colors.blueGrey,
              ),
              title: const Text('Outline Pin Wilayah'),
              value: _currentShowRegionOutline,
              onChanged: (bool value) async {
                await AppSettings.saveShowRegionPinOutline(value);
                setState(() => _currentShowRegionOutline = value);
              },
            ),
            if (_currentShowRegionOutline) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ketebalan Garis',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Slider(
                            value: _currentRegionOutlineWidth,
                            min: 1.0,
                            max: 6.0,
                            divisions: 10,
                            label: _currentRegionOutlineWidth.toStringAsFixed(
                              1,
                            ),
                            onChanged: (val) async {
                              setState(() => _currentRegionOutlineWidth = val);
                              await AppSettings.saveRegionPinOutlineWidth(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildColorCircle(
                      _currentRegionOutlineColor,
                      () => _showColorPickerDialog(
                        'Warna Outline',
                        _currentRegionOutlineColor,
                        (c) async {
                          setState(() => _currentRegionOutlineColor = c);
                          await AppSettings.saveRegionOutlineColor(c.value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(indent: 56),
            SwitchListTile(
              secondary: Icon(Icons.text_fields, color: Colors.blueGrey),
              title: const Text('Label Nama Distrik'),
              value: _currentShowRegionDistrictNames,
              onChanged: (bool value) async {
                await AppSettings.saveShowRegionDistrictNames(value);
                setState(() => _currentShowRegionDistrictNames = value);
              },
            ),
            if (_currentShowRegionDistrictNames)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: const Text('Warna Teks Label'),
                trailing: _buildColorCircle(
                  _currentRegionNameColor,
                  () => _showColorPickerDialog(
                    'Pilih Warna Teks',
                    _currentRegionNameColor,
                    (c) async {
                      setState(() => _currentRegionNameColor = c);
                      await AppSettings.saveRegionNameColor(c.value);
                    },
                  ),
                ),
              ),
          ]),

          const SizedBox(height: 24),

          // --- 4. Lainnya ---
          _buildSectionHeader('Lainnya'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.format_list_bulleted, color: Colors.purple),
              title: const Text('Bentuk Ikon Daftar'),
              trailing: _buildDropdown(
                value: _currentListIconShape,
                onChanged: (val) async {
                  if (val != null) {
                    await AppSettings.saveListIconShape(val);
                    setState(() => _currentListIconShape = val);
                  }
                },
              ),
            ),
            const Divider(indent: 56),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.teal),
              title: const Text('Tentang Aplikasi'),
              subtitle: const Text('Versi & Pengembang'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: FontWeight.w500,
        ),
        onChanged: onChanged,
        items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
            .map(
              (val) => DropdownMenuItem(
                value: val,
                child: Text(
                  val == 'Tidak Ada (Tanpa Latar)' ? 'Tanpa Latar' : val,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required Color color,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title),
          trailing: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Mengikuti Sistem';
      case ThemeMode.light:
        return 'Mode Terang';
      case ThemeMode.dark:
        return 'Mode Gelap';
    }
  }
}
