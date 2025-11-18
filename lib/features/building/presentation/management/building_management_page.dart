// lib/features/building/presentation/management/building_management_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/region/presentation/management/region_detail_page.dart';
import 'package:mind_palace_manager/permission_helper.dart';
// --- BARU: Import Peta Dunia ---
import 'package:mind_palace_manager/features/world/presentation/map/world_map_editor_page.dart';
import 'package:mind_palace_manager/features/world/presentation/map/world_map_viewer_page.dart';

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

  // --- FUNGSI PETA DUNIA ---
  void _openWorldMapEditor() {
    if (AppSettings.baseBuildingsPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => WorldMapEditorPage(
            worldDirectory: Directory(AppSettings.baseBuildingsPath!),
          ),
        ),
      );
    }
  }

  void _openWorldMapViewer() {
    if (AppSettings.baseBuildingsPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => WorldMapViewerPage(
            worldDirectory: Directory(AppSettings.baseBuildingsPath!),
          ),
        ),
      );
    }
  }
  // -------------------------

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

      final iconType = data['icon_type'];
      final iconData = data['icon_data'];

      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(regionDir.path, iconData.toString()));
        if (await imageFile.exists()) {
          return {'type': 'image', 'data': iconData, 'file': imageFile};
        } else {
          // Jika file tidak ada, kembalikan ke default.
          return {'type': null, 'data': null};
        }
      }

      return {'type': iconType, 'data': iconData};
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

    // Cek gambar peta wilayah untuk opsi "Gunakan Peta Wilayah"
    String? currentMapImageName;
    try {
      final jsonFile = File(p.join(regionDir.path, 'region_data.json'));
      if (await jsonFile.exists()) {
        final data = json.decode(await jsonFile.readAsString());
        currentMapImageName =
            data['map_image']; // Ini adalah file region_map.ext
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
                // Periksa apakah ini referensi peta untuk teks yang berbeda
                if (_editIconImagePath!.startsWith('MAP_IMAGE_REF:')) {
                  currentImageText =
                      'Referensi Peta: ${p.basename(_editIconImagePath!.substring(14))}';
                } else {
                  currentImageText =
                      'File baru: ${p.basename(_editIconImagePath!)}';
                }
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
                                final mapFile = File(
                                  p.join(regionDir.path, currentMapImageName),
                                );
                                if (await mapFile.exists()) {
                                  // --- PERUBAHAN: Set path ke marker referensi ---
                                  setDialogState(() {
                                    // Gunakan penanda referensi langsung ke nama file peta region (region_map.ext)
                                    _editIconImagePath =
                                        'MAP_IMAGE_REF:$currentMapImageName';
                                  });
                                  // --- SELESAI PERUBAHAN ---
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'File peta wilayah tidak ditemukan.',
                                        ),
                                      ),
                                    );
                                  }
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

      // 1. Rename
      if (newName != p.basename(originalDir.path)) {
        final newPath = p.join(originalDir.parent.path, newName);
        currentDir = await originalDir.rename(newPath);
      }

      // 2. Icon Logic
      String? finalIconType;
      dynamic finalIconData;

      // Variabel untuk menampung nama file icon fixed lama yang perlu dihapus
      String? oldFixedIconName;
      if (oldType == 'image' && oldData.toString().startsWith('region_icon.')) {
        oldFixedIconName = oldData.toString();
      }

      if (_editIconType == 'Teks') {
        finalIconType = 'text';
        finalIconData = _editIconTextController.text.trim();
      } else if (_editIconType == 'Gambar') {
        if (_editIconImagePath != null) {
          finalIconType = 'image';

          if (_editIconImagePath!.startsWith('MAP_IMAGE_REF:')) {
            // --- PERUBAHAN: Referensi Peta Wilayah ---
            // Gunakan nama file peta wilayah (region_map.ext)
            finalIconData = _editIconImagePath!.substring(14);
            // --- SELESAI PERUBAHAN ---
          } else {
            // File baru dipilih (bukan peta) - Lakukan copy ke fixed name

            final extension = p.extension(_editIconImagePath!);
            const fixedIconBaseName = 'region_icon';
            final fixedIconName = '$fixedIconBaseName$extension';
            finalIconData = fixedIconName;

            final sourceFile = File(_editIconImagePath!);
            final destPath = p.join(currentDir.path, finalIconData);

            // Copy file baru
            if (sourceFile.absolute.path != File(destPath).absolute.path) {
              await sourceFile.copy(destPath);
            }
          }
        } else if (oldType == 'image') {
          finalIconType = 'image';
          finalIconData = oldData;
        }
      } else {
        finalIconType = null;
        finalIconData = null;
      }

      // 3. Bersihkan file ikon lama yang tersimpan (hanya 'region_icon.ext')
      if (oldFixedIconName != null) {
        // Hapus jika tipe ikon diubah ke Teks/Default, ATAU diganti ke file peta, ATAU diganti ke file ikon baru dengan ekstensi berbeda.
        // File peta wilayah dinamakan 'region_map.ext'.

        final bool isBeingReplaced =
            finalIconType != 'image' ||
            (finalIconData != oldFixedIconName &&
                !finalIconData.toString().startsWith('region_map.'));

        if (isBeingReplaced) {
          try {
            final oldImageFile = File(
              p.join(currentDir.path, oldFixedIconName),
            );
            if (await oldImageFile.exists()) {
              await oldImageFile.delete();
            }
          } catch (e) {
            print('Gagal menghapus gambar ikon fixed lama: $e');
          }
        }
      }

      // 4. Update JSON
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
          // --- BARU: Tombol Viewer Peta Dunia ---
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Lihat Peta Dunia',
            onPressed: _openWorldMapViewer,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegions,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: _buildBody(),
      // --- BARU: Mengubah FAB menjadi Kolom untuk akses Editor dan Create ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'world_map_editor',
            onPressed: _openWorldMapEditor,
            tooltip: 'Edit Peta Dunia',
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.map, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_region',
            onPressed: _showCreateRegionDialog,
            tooltip: 'Buat Wilayah Baru',
            child: const Icon(Icons.public),
          ),
        ],
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildIconContainer(
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.hasError) {
                return _buildIconContainer(const Icon(Icons.public));
              }

              final type = snapshot.data!['type'];
              final data = snapshot.data!['data'];
              final imageFile = snapshot.data!['file'] as File?;

              if (type == 'text' && data != null) {
                return _buildIconContainer(
                  Text(
                    data.toString(),
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (type == 'image' && imageFile != null) {
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
