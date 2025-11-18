// lib/features/building/presentation/management/building_management_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/region/presentation/management/region_detail_page.dart'; // Pastikan file ini sudah dibuat
import 'package:mind_palace_manager/permission_helper.dart';

class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  List<Directory> _regionFolders = [];
  bool _isLoading = false;
  final TextEditingController _newRegionController = TextEditingController();

  // --- Controller untuk Edit ---
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editIconTextController = TextEditingController();
  String _editIconType = 'Default';
  String? _editIconImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRegions());
  }

  @override
  void dispose() {
    _newRegionController.dispose();
    _editNameController.dispose();
    _editIconTextController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoading = true;
    });

    bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin penyimpanan ditolak. Tidak dapat memuat wilayah.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

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
      final rootDir = Directory(AppSettings.baseBuildingsPath!);
      if (!await rootDir.exists()) {
        await rootDir.create(recursive: true);
      }

      final entities = await rootDir.list().toList();
      setState(() {
        _regionFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat wilayah: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreateRegionDialog() async {
    _newRegionController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Wilayah Baru'),
          content: TextField(
            controller: _newRegionController,
            decoration: const InputDecoration(hintText: 'Nama Wilayah'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Buat'),
              onPressed: _createNewRegion,
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewRegion() async {
    if (AppSettings.baseBuildingsPath == null) {
      Navigator.of(context).pop();
      _loadRegions();
      return;
    }

    final String regionName = _newRegionController.text.trim();
    if (regionName.isEmpty) return;

    try {
      final newRegionPath = p.join(AppSettings.baseBuildingsPath!, regionName);
      final newDir = Directory(newRegionPath);
      await newDir.create(recursive: true);

      // Buat file data awal untuk wilayah
      final dataJsonFile = File(p.join(newRegionPath, 'region_data.json'));
      await dataJsonFile.writeAsString(
        json.encode({
          "map_image": null,
          "district_placements": [],
          "icon_type": null,
          "icon_data": null,
        }),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
      await _loadRegions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wilayah "$regionName" berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat wilayah: $e')));
      }
    }
  }

  // --- HELPER IKON ---
  Future<Map<String, dynamic>> _getRegionIconData(Directory regionDir) async {
    try {
      final jsonFile = File(p.join(regionDir.path, 'region_data.json'));
      if (!await jsonFile.exists()) {
        return {'type': null, 'data': null};
      }

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
      case 'Bulat':
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: imageFile != null ? FileImage(imageFile) : null,
          onBackgroundImageError: imageFile != null
              ? (e, s) => const Icon(Icons.image_not_supported)
              : null,
          child: imageFile == null ? child : null,
        );
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
                  errorBuilder: (c, e, s) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                )
              : Center(child: child),
        );
      case 'Tidak Ada (Tanpa Latar)':
      default:
        return SizedBox(
          width: size,
          height: size,
          child: imageFile != null
              ? Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                )
              : Center(child: child),
        );
    }
  }

  // --- EDIT WILAYAH ---
  Future<void> _showEditRegionDialog(Directory regionDir) async {
    final currentName = p.basename(regionDir.path);
    final iconInfo = await _getRegionIconData(regionDir);
    final currentType = iconInfo['type'] ?? 'Default';
    final currentData = iconInfo['data'];

    // Cek gambar peta di region_data.json
    String? currentMapImageName;
    try {
      final jsonFile = File(p.join(regionDir.path, 'region_data.json'));
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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String currentImageText = '...';
            if (_editIconType == 'Gambar') {
              if (_editIconImagePath != null) {
                currentImageText =
                    'File baru: ${p.basename(_editIconImagePath!)}';
              } else if (currentType == 'image' && currentData != null) {
                currentImageText = 'Gambar saat ini: $currentData';
              } else {
                currentImageText = 'Pilih Gambar Ikon';
              }
            }

            return AlertDialog(
              title: const Text('Ubah Info Wilayah'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Wilayah'),
                    TextField(
                      controller: _editNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Wilayah Baru',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ikon'),
                    DropdownButton<String>(
                      value: _editIconType,
                      isExpanded: true,
                      items: ['Default', 'Teks', 'Gambar'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _editIconType = newValue!;
                        });
                      },
                    ),
                    if (_editIconType == 'Teks')
                      TextField(
                        controller: _editIconTextController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan 1-2 karakter',
                        ),
                        maxLength: 2,
                      ),
                    if (_editIconType == 'Gambar')
                      Column(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Pilih Gambar'),
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles(type: FileType.image);
                              if (result != null &&
                                  result.files.single.path != null) {
                                setDialogState(() {
                                  _editIconImagePath =
                                      result.files.single.path!;
                                });
                              }
                            },
                          ),
                          if (currentMapImageName != null)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.map),
                              label: const Text('Gunakan Peta Wilayah'),
                              onPressed: () async {
                                // Salin gambar peta ke temp
                                try {
                                  final mapFile = File(
                                    p.join(regionDir.path, currentMapImageName),
                                  );
                                  if (await mapFile.exists()) {
                                    final tempDir = Directory.systemTemp;
                                    final extension = p.extension(
                                      currentMapImageName!,
                                    );
                                    final tempFile = File(
                                      p.join(
                                        tempDir.path,
                                        'temp_map_region_${DateTime.now().millisecondsSinceEpoch}$extension',
                                      ),
                                    );
                                    await mapFile.copy(tempFile.path);
                                    setDialogState(() {
                                      _editIconImagePath = tempFile.path;
                                    });
                                  }
                                } catch (e) {
                                  print('Gagal menyalin peta: $e');
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
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Simpan'),
                  onPressed: () {
                    if (_editNameController.text.trim().isEmpty) return;
                    Navigator.of(context).pop();
                    _saveRegionChanges(regionDir, currentType, currentData);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRegionChanges(
    Directory originalDir,
    String? oldType,
    dynamic oldData,
  ) async {
    setState(() => _isLoading = true);
    try {
      final newName = _editNameController.text.trim();
      Directory currentDir = originalDir;

      // 1. Rename Folder
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
          final sourceFile = File(_editIconImagePath!);
          final destPath = p.join(currentDir.path, finalIconData);
          if (sourceFile.absolute.path != File(destPath).absolute.path) {
            await sourceFile.copy(destPath);
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
      final jsonFile = File(p.join(currentDir.path, 'region_data.json'));
      Map<String, dynamic> jsonData = {};
      if (await jsonFile.exists()) {
        try {
          jsonData = json.decode(await jsonFile.readAsString());
        } catch (_) {}
      }

      jsonData['icon_type'] = finalIconType;
      jsonData['icon_data'] = finalIconData;
      jsonData['map_image'] ??= null;
      jsonData['district_placements'] ??= [];

      await jsonFile.writeAsString(json.encode(jsonData));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Wilayah diperbarui')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    await _loadRegions();
  }

  // --- ACTIONS ---
  void _viewRegion(Directory regionDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionDetailPage(regionDirectory: regionDir),
      ),
    );
  }

  Future<void> _deleteRegion(Directory regionDir) async {
    final regionName = p.basename(regionDir.path);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Wilayah'),
        content: Text(
          'Hapus "$regionName"?\nSemua distrik & bangunan akan hilang.',
        ),
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
      try {
        await regionDir.delete(recursive: true);
        await _loadRegions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dunia Ingatan (Wilayah)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegions,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRegionDialog,
        tooltip: 'Buat Wilayah Baru',
        child: const Icon(Icons.public), // Ikon Globe untuk Wilayah
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

    if (_regionFolders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada wilayah.\nKlik tombol + untuk membuat baru.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _regionFolders.length,
      itemBuilder: (context, index) {
        final folder = _regionFolders[index];
        final folderName = p.basename(folder.path);

        return ListTile(
          leading: FutureBuilder<Map<String, dynamic>>(
            future: _getRegionIconData(folder),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildIconContainer(const Icon(Icons.public));
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
                final imageFile = File(p.join(folder.path, data.toString()));
                return _buildIconContainer(null, imageFile: imageFile);
              }
              return _buildIconContainer(const Icon(Icons.public));
            },
          ),
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              switch (value) {
                case 'view':
                  _viewRegion(folder);
                  break;
                case 'edit':
                  _showEditRegionDialog(folder);
                  break;
                case 'delete':
                  _deleteRegion(folder);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Masuk'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Ubah Info'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
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
          onTap: () => _viewRegion(folder),
        );
      },
    );
  }
}
