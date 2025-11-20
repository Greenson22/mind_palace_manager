// lib/features/building/presentation/factory/building_factory_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
import 'package:mind_palace_manager/features/building/presentation/dialogs/move_building_dialog.dart';
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';

class BuildingFactoryPage extends StatefulWidget {
  const BuildingFactoryPage({super.key});

  @override
  State<BuildingFactoryPage> createState() => _BuildingFactoryPageState();
}

class _BuildingFactoryPageState extends State<BuildingFactoryPage> {
  Directory? _warehouseDir;
  List<Directory> _bankBuildings = [];
  bool _isLoading = false;

  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _buildingIconTextController =
      TextEditingController();
  String _buildingIconType = 'Default';
  String? _buildingIconImagePath;

  @override
  void initState() {
    super.initState();
    _initWarehouse();
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _buildingIconTextController.dispose();
    super.dispose();
  }

  Future<void> _initWarehouse() async {
    if (AppSettings.baseBuildingsPath == null) return;

    final rootPath = AppSettings.baseBuildingsPath!;
    _warehouseDir = Directory(p.join(rootPath, '_BUILDING_WAREHOUSE_'));

    if (!await _warehouseDir!.exists()) {
      await _warehouseDir!.create();
    }
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    if (_warehouseDir == null) return;
    setState(() => _isLoading = true);

    try {
      final entities = await _warehouseDir!.list().toList();
      _bankBuildings = entities.whereType<Directory>().toList();
    } catch (e) {
      debugPrint("Error loading warehouse: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<Map<String, dynamic>> _getBuildingIconData(
    Directory buildingDir,
  ) async {
    try {
      final jsonFile = File(p.join(buildingDir.path, 'data.json'));
      if (!await jsonFile.exists()) {
        return {'type': null, 'data': null};
      }
      final content = await jsonFile.readAsString();
      final data = json.decode(content);

      final iconType = data.containsKey('icon_type') ? data['icon_type'] : null;
      final iconData = data.containsKey('icon_data') ? data['icon_data'] : null;

      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(buildingDir.path, iconData.toString()));
        if (await imageFile.exists()) {
          return {'type': 'image', 'data': iconData, 'file': imageFile};
        } else {
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

  Future<void> _showBuildingDialog({Directory? buildingToEdit}) async {
    final bool isEdit = buildingToEdit != null;

    _buildingNameController.text = isEdit
        ? p.basename(buildingToEdit.path)
        : '';
    _buildingIconType = 'Default';
    _buildingIconTextController.clear();
    _buildingIconImagePath = null;

    String? oldType;
    dynamic oldData;
    if (isEdit) {
      final iconData = await _getBuildingIconData(buildingToEdit);
      oldType = iconData['type'];
      oldData = iconData['data'];

      if (oldType == 'text') {
        _buildingIconType = 'Teks';
        _buildingIconTextController.text = oldData ?? '';
      } else if (oldType == 'image') {
        _buildingIconType = 'Gambar';
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String currentImageText = '...';
          if (_buildingIconType == 'Gambar') {
            if (_buildingIconImagePath != null) {
              currentImageText = 'Baru: ${p.basename(_buildingIconImagePath!)}';
            } else if (isEdit && oldType == 'image') {
              currentImageText = 'Saat ini: $oldData';
            } else {
              currentImageText = 'Pilih Gambar';
            }
          }

          return AlertDialog(
            title: Text(isEdit ? 'Ubah Info Template' : 'Buat Template Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _buildingNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Bangunan',
                    ),
                    autofocus: !isEdit,
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: _buildingIconType,
                    isExpanded: true,
                    items: ['Default', 'Teks', 'Gambar']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => _buildingIconType = v!),
                  ),
                  if (_buildingIconType == 'Teks')
                    TextField(
                      controller: _buildingIconTextController,
                      decoration: const InputDecoration(
                        hintText: 'Karakter (1-2 huruf)',
                      ),
                      maxLength: 2,
                    ),
                  if (_buildingIconType == 'Gambar')
                    Column(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Gambar'),
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (res != null) {
                              setDialogState(
                                () => _buildingIconImagePath =
                                    res.files.single.path!,
                              );
                            }
                          },
                        ),
                        Text(
                          currentImageText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_buildingNameController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    _saveBuilding(
                      isEdit: isEdit,
                      originalDir: buildingToEdit,
                      oldType: oldType,
                      oldData: oldData,
                    );
                  }
                },
                child: Text(isEdit ? 'Simpan' : 'Buat'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveBuilding({
    required bool isEdit,
    Directory? originalDir,
    String? oldType,
    dynamic oldData,
  }) async {
    final name = _buildingNameController.text.trim();
    Directory targetDir;

    if (isEdit && originalDir != null) {
      if (name != p.basename(originalDir.path)) {
        targetDir = await originalDir.rename(
          p.join(originalDir.parent.path, name),
        );
      } else {
        targetDir = originalDir;
      }
    } else {
      targetDir = Directory(p.join(_warehouseDir!.path, name));
      await targetDir.create();
    }

    String? iconType;
    dynamic iconData;
    String? oldImageName = (isEdit && oldType == 'image') ? oldData : null;

    if (_buildingIconType == 'Teks') {
      iconType = 'text';
      iconData = _buildingIconTextController.text.trim();
      if (iconData.isEmpty) {
        iconType = null;
        iconData = null;
      }
    } else if (_buildingIconType == 'Gambar') {
      if (_buildingIconImagePath != null) {
        final ext = p.extension(_buildingIconImagePath!);
        final uniqueName = 'icon_${DateTime.now().millisecondsSinceEpoch}$ext';
        iconType = 'image';
        iconData = uniqueName;
        await File(
          _buildingIconImagePath!,
        ).copy(p.join(targetDir.path, uniqueName));
      } else if (oldImageName != null) {
        iconType = 'image';
        iconData = oldImageName;
      }
    } else {
      iconType = null;
      iconData = null;
    }

    if (oldImageName != null &&
        (iconType != 'image' || iconData != oldImageName)) {
      final oldFile = File(p.join(targetDir.path, oldImageName));
      if (await oldFile.exists()) await oldFile.delete();
    }

    final jsonFile = File(p.join(targetDir.path, 'data.json'));
    Map<String, dynamic> jsonData = {"rooms": []};
    if (await jsonFile.exists()) {
      try {
        jsonData = json.decode(await jsonFile.readAsString());
      } catch (_) {}
    }
    jsonData['icon_type'] = iconType;
    jsonData['icon_data'] = iconData;

    await jsonFile.writeAsString(json.encode(jsonData));
    _loadBuildings();
  }

  Future<void> _deleteBuilding(Directory dir) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Template?'),
        content: const Text('Bangunan ini akan hilang permanen dari bank.'),
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
      await dir.delete(recursive: true);
      _loadBuildings();
    }
  }

  Future<void> _deployBuilding(Directory buildingDir) async {
    if (AppSettings.baseBuildingsPath == null) return;

    final Directory? targetDistrict = await showDialog<Directory>(
      context: context,
      builder: (context) => MoveBuildingDialog(
        currentRegionDir: _warehouseDir!,
        currentDistrictDir: _warehouseDir!,
        isFactoryMode: true,
      ),
    );

    if (targetDistrict == null) return;

    final String? mode = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pilih Metode Penempatan'),
        content: Text('Tujuan: ${p.basename(targetDistrict.path)}'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Salin (Copy)'),
            onPressed: () => Navigator.pop(c, 'copy'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.forward),
            label: const Text('Pindahkan'),
            onPressed: () => Navigator.pop(c, 'move'),
          ),
        ],
      ),
    );

    if (mode == null) return;

    setState(() => _isLoading = true);

    try {
      final String name = p.basename(buildingDir.path);
      String newName = name;

      final destPath = p.join(targetDistrict.path, name);
      if (await Directory(destPath).exists()) {
        newName = "${name}_${DateTime.now().millisecondsSinceEpoch}";
      }
      final finalDestPath = p.join(targetDistrict.path, newName);

      if (mode == 'move') {
        await buildingDir.rename(finalDestPath);
      } else {
        await _copyDirectory(buildingDir, Directory(finalDestPath));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bangunan berhasil di-${mode == 'move' ? 'pindahkan' : 'salin'} ke $newName',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadBuildings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal deploy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  Future<void> _exportIcon(Directory buildingDir) async {
    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atur folder export dulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final iconData = await _getBuildingIconData(buildingDir);
    if (iconData['type'] == 'image' && iconData['file'] != null) {
      final File img = iconData['file'];
      final ext = p.extension(img.path);
      final dest = p.join(
        AppSettings.exportPath!,
        'icon_export_${p.basename(buildingDir.path)}$ext',
      );
      await img.copy(dest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ikon diexport.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada gambar ikon.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewBuilding(Directory dir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => BuildingViewerPage(buildingDirectory: dir),
      ),
    );
  }

  void _editRoom(Directory dir) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => RoomEditorPage(buildingDirectory: dir)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA WARNA APPBAR ADAPTIF ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDarkMode
        ? null
        : Colors.indigo.shade50; // Null = default dark surface
    // -----------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Bangunan (Gudang)'),
        backgroundColor: appBarColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bankBuildings.isEmpty
          ? const Center(
              child: Text(
                'Bank kosong.\nBuat template bangunan di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _bankBuildings.length,
              itemBuilder: (c, i) {
                final dir = _bankBuildings[i];
                return ListTile(
                  leading: FutureBuilder<Map<String, dynamic>>(
                    future: _getBuildingIconData(dir),
                    builder: (c, s) {
                      if (!s.hasData)
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      final d = s.data!;
                      Widget? child;
                      File? img;
                      if (d['type'] == 'text')
                        child = Text(
                          d['data'],
                          style: const TextStyle(fontSize: 20),
                        );
                      if (d['type'] == 'image') img = d['file'];
                      if (d['type'] == null)
                        child = const Icon(Icons.apartment);
                      return _buildIconContainer(child, imageFile: img);
                    },
                  ),
                  title: Text(p.basename(dir.path)),
                  subtitle: const Text('Status: Tersimpan di Bank'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'deploy') _deployBuilding(dir);
                      if (v == 'view') _viewBuilding(dir);
                      if (v == 'edit_room') _editRoom(dir);
                      if (v == 'edit_info')
                        _showBuildingDialog(buildingToEdit: dir);
                      if (v == 'export') _exportIcon(dir);
                      if (v == 'delete') _deleteBuilding(dir);
                    },
                    itemBuilder: (c) => [
                      const PopupMenuItem(
                        value: 'deploy',
                        child: Row(
                          children: [
                            Icon(Icons.ios_share, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Tempatkan (Deploy)'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('Lihat'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit_room',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Ruangan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit_info',
                        child: Row(
                          children: [
                            Icon(Icons.palette_outlined, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Ubah Info'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text('Export Ikon'),
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
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _viewBuilding(dir),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBuildingDialog(),
        label: const Text('Buat Template Baru'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
