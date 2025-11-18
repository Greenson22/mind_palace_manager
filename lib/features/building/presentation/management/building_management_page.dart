// lib/features/building/presentation/management/building_management_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/management/district_building_management_page.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_editor_page.dart';
import 'package:mind_palace_manager/permission_helper.dart';

class BuildingManagementPage extends StatefulWidget {
  const BuildingManagementPage({super.key});

  @override
  State<BuildingManagementPage> createState() => _BuildingManagementPageState();
}

class _BuildingManagementPageState extends State<BuildingManagementPage> {
  List<Directory> _districtFolders = [];
  bool _isLoading = false;
  final TextEditingController _newDistrictController = TextEditingController();

  // --- Controller untuk Edit ---
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editIconTextController = TextEditingController();
  String _editIconType = 'Default';
  String? _editIconImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDistricts());
  }

  @override
  void dispose() {
    _newDistrictController.dispose();
    _editNameController.dispose();
    _editIconTextController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() {
      _isLoading = true;
    });

    bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin penyimpanan ditolak. Tidak dapat memuat distrik.',
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
        _districtFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat distrik: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreateDistrictDialog() async {
    _newDistrictController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Distrik Baru'),
          content: TextField(
            controller: _newDistrictController,
            decoration: const InputDecoration(hintText: 'Nama Distrik'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Buat'),
              onPressed: _createNewDistrict,
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewDistrict() async {
    if (AppSettings.baseBuildingsPath == null) {
      Navigator.of(context).pop();
      _loadDistricts();
      return;
    }

    final String districtName = _newDistrictController.text.trim();
    if (districtName.isEmpty) return;

    try {
      final newDistrictPath = p.join(
        AppSettings.baseBuildingsPath!,
        districtName,
      );
      final newDir = Directory(newDistrictPath);
      await newDir.create(recursive: true);

      final dataJsonFile = File(p.join(newDistrictPath, 'district_data.json'));
      await dataJsonFile.writeAsString(
        json.encode({
          "map_image": null,
          "building_placements": [],
          "icon_type": null,
          "icon_data": null,
        }),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
      await _loadDistricts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Distrik "$districtName" berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat distrik: $e')));
      }
    }
  }

  // --- Fungsi Helper untuk Ikon ---

  Future<Map<String, dynamic>> _getDistrictIconData(
    Directory districtDir,
  ) async {
    try {
      final jsonFile = File(p.join(districtDir.path, 'district_data.json'));
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

  // --- Dialog Edit Distrik (DIPERBARUI) ---

  Future<void> _showEditDistrictDialog(Directory districtDir) async {
    // 1. Muat data saat ini
    final currentName = p.basename(districtDir.path);
    final iconInfo = await _getDistrictIconData(districtDir);
    final currentType = iconInfo['type'] ?? 'Default';
    final currentData = iconInfo['data'];

    // --- TAMBAHAN: Cek apakah ada gambar peta ---
    String? currentMapImageName;
    try {
      final jsonFile = File(p.join(districtDir.path, 'district_data.json'));
      if (await jsonFile.exists()) {
        final data = json.decode(await jsonFile.readAsString());
        currentMapImageName = data['map_image'];
      }
    } catch (_) {}
    // -------------------------------------------

    // 2. Reset Controller
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

    // 3. Tampilkan Dialog
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
              title: const Text('Ubah Nama & Ikon Distrik'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bagian Nama
                    Text(
                      'Nama Distrik',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextField(
                      controller: _editNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Distrik Baru',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bagian Ikon
                    Text(
                      'Ikon Distrik',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
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
                          hintText: 'Masukkan 1-2 karakter (cth: 🏠)',
                        ),
                        maxLength: 2,
                      ),

                    if (_editIconType == 'Gambar')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.image),
                                  label: const Text('Pilih File'),
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
                              ),
                            ],
                          ),
                          // --- TAMBAHAN: Tombol Gunakan Map ---
                          if (currentMapImageName != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.map),
                                label: const Text('Gunakan Gambar Peta'),
                                onPressed: () async {
                                  try {
                                    // Salin gambar peta ke temp file agar aman jika folder di-rename
                                    final mapFile = File(
                                      p.join(
                                        districtDir.path,
                                        currentMapImageName,
                                      ),
                                    );
                                    if (await mapFile.exists()) {
                                      final tempDir = Directory.systemTemp;
                                      final extension = p.extension(
                                        currentMapImageName!,
                                      );
                                      final tempFile = File(
                                        p.join(
                                          tempDir.path,
                                          'temp_map_icon_${DateTime.now().millisecondsSinceEpoch}$extension',
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
                            ),
                          ],
                          // ------------------------------------
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              currentImageText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
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
                    if (_editNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama distrik tidak boleh kosong.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop(); // Tutup dialog
                    _saveDistrictChanges(districtDir, currentType, currentData);
                  },
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

      // 1. Ganti Nama Folder (jika berubah)
      if (newName != p.basename(originalDir.path)) {
        final newPath = p.join(originalDir.parent.path, newName);
        currentDir = await originalDir.rename(newPath);
      }

      // 2. Proses Data Ikon
      String? finalIconType;
      dynamic finalIconData;

      if (_editIconType == 'Teks') {
        finalIconType = 'text';
        finalIconData = _editIconTextController.text.trim();
      } else if (_editIconType == 'Gambar') {
        if (_editIconImagePath != null) {
          // User pilih gambar baru (atau dari temp map) -> Salin ke folder distrik
          finalIconType = 'image';
          finalIconData = p.basename(_editIconImagePath!);
          final sourceFile = File(_editIconImagePath!);
          final destPath = p.join(currentDir.path, finalIconData);

          // Cek untuk menghindari copy ke diri sendiri jika path kebetulan sama
          if (sourceFile.absolute.path != File(destPath).absolute.path) {
            await sourceFile.copy(destPath);
          }
        } else if (oldType == 'image' && oldData != null) {
          // User tidak ganti gambar, tetap pakai yang lama
          finalIconType = 'image';
          finalIconData = oldData;
        }
      } else {
        finalIconType = null;
        finalIconData = null;
      }

      // 3. Update district_data.json
      final jsonFile = File(p.join(currentDir.path, 'district_data.json'));
      Map<String, dynamic> jsonData = {};
      if (await jsonFile.exists()) {
        try {
          jsonData = json.decode(await jsonFile.readAsString());
        } catch (_) {}
      }

      jsonData['icon_type'] = finalIconType;
      jsonData['icon_data'] = finalIconData;

      // Pastikan field lain tetap ada
      jsonData['map_image'] ??= null;
      jsonData['building_placements'] ??= [];

      await jsonFile.writeAsString(json.encode(jsonData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Distrik berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui distrik: $e')),
        );
      }
    }

    // Reload list
    await _loadDistricts();
  }

  void _viewDistrict(Directory districtDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DistrictBuildingManagementPage(districtDirectory: districtDir),
      ),
    );
  }

  void _editDistrictMap(Directory districtDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DistrictMapEditorPage(districtDirectory: districtDir),
      ),
    );
  }

  Future<void> _deleteDistrict(Directory districtDir) async {
    final districtName = p.basename(districtDir.path);

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Distrik'),
          content: Text(
            'Apakah Anda yakin ingin menghapus distrik "$districtName"?\n\n'
            'PERINGATAN: Tindakan ini akan menghapus SEMUA bangunan di dalamnya secara permanen.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      try {
        await districtDir.delete(recursive: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Distrik "$districtName" berhasil dihapus.'),
            ),
          );
        }
        await _loadDistricts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus distrik: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Distrik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDistricts,
            tooltip: 'Muat Ulang Daftar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDistrictDialog,
        tooltip: 'Buat Distrik Baru',
        child: const Icon(Icons.add_location_alt),
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

    if (_districtFolders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada distrik.\nKlik tombol + untuk membuat yang baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _districtFolders.length,
      itemBuilder: (context, index) {
        final folder = _districtFolders[index];
        final folderName = p.basename(folder.path);

        // --- Widget Ikon Dinamis ---
        final Widget leadingIcon = FutureBuilder<Map<String, dynamic>>(
          future: _getDistrictIconData(folder),
          key: ValueKey(folder.path),
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
              final imageFile = File(p.join(folder.path, data.toString()));
              return _buildIconContainer(null, imageFile: imageFile);
            }

            return _buildIconContainer(const Icon(Icons.holiday_village));
          },
        );
        // --- Selesai ---

        return ListTile(
          leading: leadingIcon,
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opsi Distrik',
            onSelected: (String value) {
              switch (value) {
                case 'view':
                  _viewDistrict(folder);
                  break;
                case 'edit_map':
                  _editDistrictMap(folder);
                  break;
                case 'edit_info':
                  _showEditDistrictDialog(folder);
                  break;
                case 'delete':
                  _deleteDistrict(folder);
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
                    Text('Lihat'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit_map',
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit Peta'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit_info',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Ubah Nama & Ikon'),
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
          onTap: () => _viewDistrict(folder),
        );
      },
    );
  }
}
