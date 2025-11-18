// lib/features/region/presentation/management/region_detail_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/management/district_building_management_page.dart';
// Import Editor & Viewer Peta Distrik (yang sudah ada)
import 'package:mind_palace_manager/features/building/presentation/map/district_map_editor_page.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_viewer_page.dart';
// Import Peta Wilayah (untuk FloatingActionButton)
import 'package:mind_palace_manager/features/region/presentation/map/region_map_editor_page.dart';
import 'package:mind_palace_manager/features/region/presentation/map/region_map_viewer_page.dart';

class RegionDetailPage extends StatefulWidget {
  final Directory regionDirectory;

  const RegionDetailPage({super.key, required this.regionDirectory});

  @override
  State<RegionDetailPage> createState() => _RegionDetailPageState();
}

class _RegionDetailPageState extends State<RegionDetailPage> {
  List<Directory> _districtFolders = [];
  bool _isLoading = false;
  final TextEditingController _newDistrictController = TextEditingController();

  // --- Controller untuk Edit Distrik ---
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editIconTextController = TextEditingController();
  String _editIconType = 'Default';
  String? _editIconImagePath;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  @override
  void dispose() {
    _newDistrictController.dispose();
    _editNameController.dispose();
    _editIconTextController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() => _isLoading = true);
    try {
      final entities = await widget.regionDirectory.list().toList();
      setState(() {
        _districtFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat distrik: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  // --- FUNGSI BUAT BARU ---
  Future<void> _createNewDistrict() async {
    _newDistrictController.clear();
    String? name = await showDialog<String>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Buat Distrik Baru'),
          content: TextField(
            controller: _newDistrictController,
            decoration: const InputDecoration(hintText: 'Nama Distrik'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, _newDistrictController.text),
              child: const Text('Buat'),
            ),
          ],
        );
      },
    );

    if (name != null && name.trim().isNotEmpty) {
      try {
        final newPath = p.join(widget.regionDirectory.path, name.trim());
        final newDir = Directory(newPath);
        await newDir.create();

        // Inisialisasi data distrik
        await File(p.join(newPath, 'district_data.json')).writeAsString(
          json.encode({
            "map_image": null,
            "building_placements": [],
            "icon_type": null,
            "icon_data": null,
          }),
        );

        _loadDistricts();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Distrik "$name" dibuat')));
        }
      } catch (e) {
        print("Error creating district: $e");
      }
    }
  }

  // --- HELPER IKON ---
  Future<Map<String, dynamic>> _getDistrictIconData(
    Directory districtDir,
  ) async {
    try {
      final jsonFile = File(p.join(districtDir.path, 'district_data.json'));
      if (!await jsonFile.exists()) return {'type': null, 'data': null};
      final content = await jsonFile.readAsString();
      final data = json.decode(content);
      return {'type': data['icon_type'], 'data': data['icon_data']};
    } catch (e) {
      return {'type': null, 'data': null};
    }
  }

  Widget _buildIconContainer(Widget? child, {File? imageFile}) {
    double size = 40.0;
    switch (AppSettings.listIconShape) {
      case 'Kotak':
        return Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: imageFile == null ? Colors.grey.shade200 : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: imageFile != null
              ? Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.error),
                )
              : Center(child: child),
        );
      case 'Tidak Ada (Tanpa Latar)':
        return SizedBox(
          width: size,
          height: size,
          child: imageFile != null
              ? Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.error),
                )
              : Center(child: child),
        );
      case 'Bulat':
      default:
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: imageFile != null ? FileImage(imageFile) : null,
          child: imageFile == null ? child : null,
        );
    }
  }

  // --- FUNGSI EDIT DISTRIK (Nama & Ikon) ---
  Future<void> _showEditDistrictDialog(Directory districtDir) async {
    final currentName = p.basename(districtDir.path);
    final iconInfo = await _getDistrictIconData(districtDir);
    final currentType = iconInfo['type'] ?? 'Default';
    final currentData = iconInfo['data'];

    // Cek gambar peta distrik untuk opsi "Gunakan Peta"
    String? currentMapImageName;
    try {
      final jsonFile = File(p.join(districtDir.path, 'district_data.json'));
      if (await jsonFile.exists()) {
        final data = json.decode(await jsonFile.readAsString());
        currentMapImageName = data['map_image'];
      }
    } catch (_) {}

    _editNameController.text = currentName;
    _editIconImagePath = null;

    if (currentType == 'text') {
      _editIconType = 'Teks';
      _editIconTextController.text = currentData ?? '';
    } else if (currentType == 'image') {
      _editIconType = 'Gambar';
      _editIconTextController.clear();
    } else {
      _editIconType = 'Default';
      _editIconTextController.clear();
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String currentImageText = '...';
            if (_editIconType == 'Gambar') {
              if (_editIconImagePath != null) {
                currentImageText = 'Baru: ${p.basename(_editIconImagePath!)}';
              } else if (currentType == 'image' && currentData != null) {
                currentImageText = 'Saat ini: $currentData';
              } else {
                currentImageText = 'Pilih Gambar';
              }
            }

            return AlertDialog(
              title: const Text('Ubah Info Distrik'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _editNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Distrik',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: _editIconType,
                      isExpanded: true,
                      items: ['Default', 'Teks', 'Gambar'].map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => _editIconType = v!),
                    ),
                    if (_editIconType == 'Teks')
                      TextField(
                        controller: _editIconTextController,
                        decoration: const InputDecoration(
                          labelText: 'Karakter (cth: 🏘️)',
                        ),
                        maxLength: 2,
                      ),
                    if (_editIconType == 'Gambar')
                      Column(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Pilih File Gambar'),
                            onPressed: () async {
                              var res = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );
                              if (res != null) {
                                setDialogState(
                                  () => _editIconImagePath =
                                      res.files.single.path,
                                );
                              }
                            },
                          ),
                          if (currentMapImageName != null)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.map),
                              label: const Text('Gunakan Peta Distrik'),
                              onPressed: () async {
                                try {
                                  final mapFile = File(
                                    p.join(
                                      districtDir.path,
                                      currentMapImageName,
                                    ),
                                  );
                                  if (await mapFile.exists()) {
                                    // Copy ke temp
                                    final tempDir = Directory.systemTemp;
                                    final ext = p.extension(
                                      currentMapImageName!,
                                    );
                                    final tempFile = File(
                                      p.join(
                                        tempDir.path,
                                        'temp_dist_icon_${DateTime.now().millisecondsSinceEpoch}$ext',
                                      ),
                                    );
                                    await mapFile.copy(tempFile.path);
                                    setDialogState(
                                      () => _editIconImagePath = tempFile.path,
                                    );
                                  }
                                } catch (e) {
                                  print("Gagal salin peta: $e");
                                }
                              },
                            ),
                          Text(
                            currentImageText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_editNameController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    _saveDistrictChanges(districtDir, currentType, currentData);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveDistrictChanges(
    Directory originalDir,
    String? oldType,
    dynamic oldData,
  ) async {
    setState(() => _isLoading = true);
    try {
      final newName = _editNameController.text.trim();
      Directory currentDir = originalDir;

      // 1. Rename
      if (newName != p.basename(originalDir.path)) {
        final newPath = p.join(originalDir.parent.path, newName);
        currentDir = await originalDir.rename(newPath);
      }

      // 2. Icon Logic
      String? finalIconType;
      dynamic finalIconData;

      if (_editIconType == 'Teks') {
        finalIconType = 'text';
        finalIconData = _editIconTextController.text.trim();
      } else if (_editIconType == 'Gambar') {
        if (_editIconImagePath != null) {
          finalIconType = 'image';
          finalIconData = p.basename(_editIconImagePath!);
          final destPath = p.join(currentDir.path, finalIconData);
          // Hindari copy ke diri sendiri
          if (File(_editIconImagePath!).absolute.path !=
              File(destPath).absolute.path) {
            await File(_editIconImagePath!).copy(destPath);
          }
        } else if (oldType == 'image') {
          finalIconType = 'image';
          finalIconData = oldData;
        }
      } else {
        finalIconType = null;
        finalIconData = null;
      }

      // 3. Update JSON
      final jsonFile = File(p.join(currentDir.path, 'district_data.json'));
      Map<String, dynamic> jsonData = {};
      if (await jsonFile.exists()) {
        jsonData = json.decode(await jsonFile.readAsString());
      }

      jsonData['icon_type'] = finalIconType;
      jsonData['icon_data'] = finalIconData;
      // Pastikan field map terjaga
      jsonData['map_image'] ??= null;
      jsonData['building_placements'] ??= [];

      await jsonFile.writeAsString(json.encode(jsonData));
      _loadDistricts();
    } catch (e) {
      print(e);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteDistrict(Directory districtDir) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Distrik?'),
        content: const Text('Semua bangunan di dalamnya akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await districtDir.delete(recursive: true);
      _loadDistricts();
    }
  }

  // --- NAVIGASI ---
  void _openDistrict(Directory districtDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) =>
            DistrictBuildingManagementPage(districtDirectory: districtDir),
      ),
    );
  }

  void _editDistrictMap(Directory districtDir) {
    // INI DIA: Menghubungkan ke Editor Peta Distrik yang lama
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => DistrictMapEditorPage(districtDirectory: districtDir),
      ),
    );
  }

  void _openRegionMapEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) =>
            RegionMapEditorPage(regionDirectory: widget.regionDirectory),
      ),
    );
  }

  void _openRegionMapViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) =>
            RegionMapViewerPage(regionDirectory: widget.regionDirectory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wilayah: ${p.basename(widget.regionDirectory.path)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Lihat Peta Wilayah',
            onPressed: _openRegionMapViewer,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDistricts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDistrictList(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'map_region',
            onPressed: _openRegionMapEditor,
            backgroundColor: Colors.blue.shade100,
            tooltip: 'Edit Peta Wilayah',
            child: const Icon(Icons.map, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_district',
            onPressed: _createNewDistrict,
            tooltip: 'Buat Distrik Baru',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictList() {
    if (_districtFolders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada distrik di wilayah ini.\nKlik tombol + untuk menambah.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _districtFolders.length,
      itemBuilder: (context, index) {
        final dir = _districtFolders[index];
        return ListTile(
          leading: FutureBuilder<Map<String, dynamic>>(
            future: _getDistrictIconData(dir),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildIconContainer(const Icon(Icons.holiday_village));
              }
              final type = snapshot.data!['type'];
              final data = snapshot.data!['data'];

              if (type == 'text' && data != null) {
                return _buildIconContainer(
                  Text(
                    data.toString(),
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (type == 'image' && data != null) {
                final imageFile = File(p.join(dir.path, data.toString()));
                return _buildIconContainer(null, imageFile: imageFile);
              }
              return _buildIconContainer(const Icon(Icons.holiday_village));
            },
          ),
          title: Text(
            p.basename(dir.path),
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Text(dir.path, style: const TextStyle(fontSize: 10)),
          // --- MENU OPSI UNTUK DISTRIK ---
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'view':
                  _openDistrict(dir);
                  break;
                case 'edit_map':
                  _editDistrictMap(dir); // <-- Akses ke Editor Peta Distrik
                  break;
                case 'edit_info':
                  _showEditDistrictDialog(dir);
                  break;
                case 'delete':
                  _deleteDistrict(dir);
                  break;
              }
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Masuk'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_map',
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit Peta'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_info',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Ubah Info'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _openDistrict(dir),
        );
      },
    );
  }
}
