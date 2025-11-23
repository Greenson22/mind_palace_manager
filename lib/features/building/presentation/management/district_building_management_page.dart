import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/editor/room_editor_page.dart';
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';
import 'package:mind_palace_manager/permission_helper.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_viewer_page.dart';
import 'package:mind_palace_manager/features/building/presentation/dialogs/move_building_dialog.dart';
import 'package:mind_palace_manager/features/building/presentation/map/district_map_editor_page.dart';

// --- IMPORT TRANSISI AWAN ---
import 'package:mind_palace_manager/features/settings/helpers/cloud_transition.dart';

// --- IMPORT PLAN EDITOR (DENAH) ---
import 'package:mind_palace_manager/features/plan_architect/presentation/plan_editor_page.dart';

class DistrictBuildingManagementPage extends StatefulWidget {
  final Directory districtDirectory;

  const DistrictBuildingManagementPage({
    super.key,
    required this.districtDirectory,
  });

  @override
  State<DistrictBuildingManagementPage> createState() =>
      _DistrictBuildingManagementPageState();
}

class _DistrictBuildingManagementPageState
    extends State<DistrictBuildingManagementPage> {
  List<Directory> _buildingFolders = [];
  bool _isLoading = false;

  // --- State untuk Expandable FAB ---
  bool _isFabOpen = false;

  // --- Controller untuk Dialog ---
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _buildingIconTextController =
      TextEditingController();
  String _buildingIconType = 'Default';
  String? _buildingIconImagePath;

  // --- VARIABEL TIPE BANGUNAN (BARU) ---
  String _selectedBuildingType = 'standard'; // 'standard' | 'plan'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuildings());
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _buildingIconTextController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() => _isLoading = true);

    bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin penyimpanan ditolak. Tidak dapat memuat bangunan.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final Directory buildingsDir = widget.districtDirectory;

    try {
      if (!await buildingsDir.exists()) {
        await buildingsDir.create(recursive: true);
      }

      final entities = await buildingsDir.list().toList();
      setState(() {
        _buildingFolders = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat bangunan: $e')));
      }
    }

    setState(() => _isLoading = false);
  }

  // --- LOGIKA BUAT BANGUNAN BARU ---

  Future<void> _showCreateBuildingDialog() async {
    _buildingNameController.clear();
    _buildingIconTextController.clear();
    _buildingIconType = 'Default';
    _buildingIconImagePath = null;
    _selectedBuildingType = 'standard'; // Reset ke default

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Bangunan Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _buildingNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Bangunan',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    // --- PILIHAN TIPE BANGUNAN ---
                    const Text(
                      "Tipe Bangunan:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text("Biasa (Ruangan & Navigasi)"),
                      value: 'standard',
                      groupValue: _selectedBuildingType,
                      onChanged: (val) =>
                          setDialogState(() => _selectedBuildingType = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text("Denah (Arsitek/Plan)"),
                      value: 'plan',
                      groupValue: _selectedBuildingType,
                      onChanged: (val) =>
                          setDialogState(() => _selectedBuildingType = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),

                    // --- PILIHAN IKON ---
                    const Text(
                      "Ikon Tampilan Luar:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _buildingIconType,
                      isExpanded: true,
                      items: ['Default', 'Teks', 'Gambar'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
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
                            label: const Text('Pilih Gambar Ikon'),
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles(type: FileType.image);
                              if (result != null &&
                                  result.files.single.path != null) {
                                setDialogState(
                                  () => _buildingIconImagePath =
                                      result.files.single.path!,
                                );
                              }
                            },
                          ),
                          if (_buildingIconImagePath != null)
                            Text(
                              'File: ${p.basename(_buildingIconImagePath!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Buat'),
                  onPressed: () {
                    if (_buildingNameController.text.trim().isNotEmpty) {
                      _createNewBuilding();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama tidak boleh kosong.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewBuilding() async {
    final String buildingName = _buildingNameController.text.trim();
    if (buildingName.isEmpty) return;

    String? iconType;
    dynamic iconData;

    try {
      if (_buildingIconType == 'Teks') {
        iconType = 'text';
        iconData = _buildingIconTextController.text.trim();
        if (iconData.isEmpty) {
          iconType = null;
          iconData = null;
        }
      } else if (_buildingIconType == 'Gambar' &&
          _buildingIconImagePath != null) {
        final extension = p.extension(_buildingIconImagePath!);
        final uniqueIconName =
            'icon_${DateTime.now().millisecondsSinceEpoch}$extension';
        iconType = 'image';
        iconData = uniqueIconName;
      }

      final newBuildingPath = p.join(
        widget.districtDirectory.path,
        buildingName,
      );
      final newDir = Directory(newBuildingPath);
      await newDir.create(recursive: true);

      if (iconType == 'image' && _buildingIconImagePath != null) {
        final sourceFile = File(_buildingIconImagePath!);
        final destinationPath = p.join(newBuildingPath, iconData);
        await sourceFile.copy(destinationPath);
      }

      final dataJsonFile = File(p.join(newBuildingPath, 'data.json'));
      final jsonData = {
        "icon_type": iconType,
        "icon_data": iconData,
        "type": _selectedBuildingType, // SIMPAN TIPE DI SINI
        "rooms": [],
      };
      await dataJsonFile.writeAsString(json.encode(jsonData));

      if (mounted) Navigator.of(context).pop();
      await _loadBuildings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bangunan "$buildingName" berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat bangunan: $e')));
      }
    }
  }

  // --- LOGIKA NAVIGASI BERDASARKAN TIPE ---
  Future<void> _viewBuilding(Directory buildingDir) async {
    String type = 'standard';
    try {
      final file = File(p.join(buildingDir.path, 'data.json'));
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        type = data['type'] ?? 'standard';
      }
    } catch (_) {}

    if (type == 'plan') {
      // Masuk ke Arsitek Denah (Editor)
      // Tidak menggunakan CloudNavigation karena ini Editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanEditorPage(buildingDirectory: buildingDir),
        ),
      );
    } else {
      // Masuk ke Viewer Biasa (Cloud Transition)
      CloudNavigation.push(
        context,
        BuildingViewerPage(buildingDirectory: buildingDir),
      );
    }
  }

  // --- LOGIKA EDIT BANGUNAN (Nama & Ikon) ---

  Future<void> _showEditBuildingDialog(Directory buildingDir) async {
    final currentName = p.basename(buildingDir.path);
    final iconData = await _getBuildingIconData(buildingDir);
    String currentType = iconData['type'] ?? 'Default';
    dynamic currentData = iconData['data'];

    _buildingNameController.text = currentName;

    if (currentType == 'text') {
      _buildingIconType = 'Teks';
      _buildingIconTextController.text = currentData ?? '';
      _buildingIconImagePath = null;
    } else if (currentType == 'image') {
      _buildingIconType = 'Gambar';
      _buildingIconTextController.clear();
      _buildingIconImagePath = null;
    } else {
      _buildingIconType = 'Default';
      _buildingIconTextController.clear();
      _buildingIconImagePath = null;
    }

    final bool? didSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String currentImageText = '...';
            if (_buildingIconType == 'Gambar') {
              if (_buildingIconImagePath != null) {
                currentImageText =
                    'File baru: ${p.basename(_buildingIconImagePath!)}';
              } else if (currentType == 'image' && currentData != null) {
                currentImageText = 'Gambar saat ini: $currentData';
              } else {
                currentImageText = 'Pilih Gambar Ikon';
              }
            }

            return AlertDialog(
              title: const Text('Ubah Info Bangunan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _buildingNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Bangunan',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ikon Bangunan',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    DropdownButton<String>(
                      value: _buildingIconType,
                      isExpanded: true,
                      items: ['Default', 'Teks', 'Gambar']
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) =>
                          setDialogState(() => _buildingIconType = newValue!),
                    ),
                    if (_buildingIconType == 'Teks')
                      TextField(
                        controller: _buildingIconTextController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan 1-2 karakter',
                        ),
                        maxLength: 2,
                      ),
                    if (_buildingIconType == 'Gambar')
                      Column(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Pilih Gambar Baru'),
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles(type: FileType.image);
                              if (result != null &&
                                  result.files.single.path != null) {
                                setDialogState(
                                  () => _buildingIconImagePath =
                                      result.files.single.path!,
                                );
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              currentImageText,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
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
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  child: const Text('Simpan'),
                  onPressed: () async {
                    if (_buildingNameController.text.trim().isEmpty) return;
                    await _saveBuildingChanges(
                      buildingDir,
                      currentType,
                      currentData,
                    );
                    if (mounted) Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (didSave == true) {
      await _loadBuildings();
    }
  }

  Future<void> _saveBuildingChanges(
    Directory originalDir,
    String? oldType,
    dynamic oldData,
  ) async {
    final newName = _buildingNameController.text.trim();
    Directory currentDir = originalDir;

    if (newName != p.basename(originalDir.path)) {
      try {
        final newPath = p.join(originalDir.parent.path, newName);
        currentDir = await originalDir.rename(newPath);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengubah nama folder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }
    }

    final jsonFile = File(p.join(currentDir.path, 'data.json'));
    Map<String, dynamic> jsonData;
    try {
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        jsonData = json.decode(content);
      } else {
        jsonData = {"rooms": []};
      }
    } catch (e) {
      jsonData = {"rooms": []};
    }

    String? iconType;
    dynamic iconData;
    String? oldImageName = oldType == 'image' ? oldData : null;

    if (_buildingIconType == 'Teks') {
      iconType = 'text';
      iconData = _buildingIconTextController.text.trim();
      if (iconData.isEmpty) {
        iconType = null;
        iconData = null;
      }
    } else if (_buildingIconType == 'Gambar') {
      if (_buildingIconImagePath != null) {
        final extension = p.extension(_buildingIconImagePath!);
        final uniqueIconName =
            'icon_${DateTime.now().millisecondsSinceEpoch}$extension';
        iconType = 'image';
        iconData = uniqueIconName;
        try {
          final sourceFile = File(_buildingIconImagePath!);
          final destinationPath = p.join(currentDir.path, iconData);
          await sourceFile.copy(destinationPath);
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyalin gambar baru: $e')),
            );
          return;
        }
      } else if (oldImageName != null) {
        iconType = 'image';
        iconData = oldImageName;
      } else {
        iconType = null;
        iconData = null;
      }
    } else {
      iconType = null;
      iconData = null;
    }

    // Hapus file lama jika tidak dipakai lagi
    if (oldImageName != null &&
        (iconType != 'image' || iconData != oldImageName)) {
      try {
        final oldImageFile = File(p.join(currentDir.path, oldImageName));
        if (await oldImageFile.exists()) await oldImageFile.delete();
      } catch (e) {
        print("Gagal menghapus gambar ikon lama: $e");
      }
    }

    jsonData['icon_type'] = iconType;
    jsonData['icon_data'] = iconData;

    try {
      await jsonFile.writeAsString(json.encode(jsonData));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Info Bangunan "$newName" berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan ikon: $e')));
    }
  }

  // --- FITUR PINDAH & RETRACT (GUDANG) ---

  Future<void> _moveBuilding(Directory buildingDir) async {
    final currentRegionDir = widget.districtDirectory.parent;

    final Directory? targetDistrict = await showDialog<Directory>(
      context: context,
      builder: (context) => MoveBuildingDialog(
        currentRegionDir: currentRegionDir,
        currentDistrictDir: widget.districtDirectory,
      ),
    );

    if (targetDistrict == null) return;

    setState(() => _isLoading = true);

    try {
      final String buildingName = p.basename(buildingDir.path);
      String newName = buildingName;

      final expectedPath = p.join(targetDistrict.path, buildingName);
      if (await Directory(expectedPath).exists()) {
        newName = "${buildingName}_${DateTime.now().millisecondsSinceEpoch}";
      }

      final finalNewPath = p.join(targetDistrict.path, newName);

      await buildingDir.rename(finalNewPath);
      await _removeBuildingFromMapData(widget.districtDirectory, buildingName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil dipindahkan ke ${p.basename(targetDistrict.path)}${newName != buildingName ? ' sebagai "$newName"' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadBuildings();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memindahkan bangunan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _retractBuilding(Directory buildingDir) async {
    if (AppSettings.baseBuildingsPath == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Simpan ke Bank Bangunan?'),
        content: const Text(
          'Bangunan akan dipindahkan dari distrik ini ke Gudang/Bank.\nData posisi di peta distrik akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final warehouseDir = Directory(
        p.join(AppSettings.baseBuildingsPath!, '_BUILDING_WAREHOUSE_'),
      );
      if (!await warehouseDir.exists()) {
        await warehouseDir.create();
      }

      final String name = p.basename(buildingDir.path);
      String newName = name;

      if (await Directory(p.join(warehouseDir.path, name)).exists()) {
        newName = "${name}_${DateTime.now().millisecondsSinceEpoch}";
      }

      await buildingDir.rename(p.join(warehouseDir.path, newName));
      await _removeBuildingFromMapData(widget.districtDirectory, name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bangunan aman tersimpan di Bank Bangunan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadBuildings();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeBuildingFromMapData(
    Directory districtDir,
    String buildingFolderName,
  ) async {
    try {
      final jsonFile = File(p.join(districtDir.path, 'district_data.json'));
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final data = json.decode(content);
        List<dynamic> placements = data['building_placements'] ?? [];
        final int initialLen = placements.length;
        placements.removeWhere(
          (item) => item['building_folder_name'] == buildingFolderName,
        );

        if (placements.length != initialLen) {
          data['building_placements'] = placements;
          await jsonFile.writeAsString(json.encode(data));
        }
      }
    } catch (e) {
      print("Warning: Gagal membersihkan data peta lama: $e");
    }
  }

  // --- FITUR LAIN (Export, Delete, Navigasi) ---

  Future<void> _exportBuildingIcon(Directory buildingDir) async {
    if (AppSettings.exportPath == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atur folder export di Pengaturan terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    try {
      final iconData = await _getBuildingIconData(buildingDir);
      final iconType = iconData['type'];
      final imageFile = iconData['file'] as File?;

      if (iconType != 'image' ||
          imageFile == null ||
          !await imageFile.exists()) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ikon bukan gambar atau file ikon tidak ditemukan.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }

      final extension = p.extension(imageFile.path);
      final now = DateTime.now();
      final fileName =
          'icon_${p.basename(buildingDir.path)}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}$extension';
      final destinationPath = p.join(AppSettings.exportPath!, fileName);
      await imageFile.copy(destinationPath);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ikon berhasil diexport ke: $destinationPath'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export ikon: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _deleteBuilding(Directory buildingDir) async {
    final buildingName = p.basename(buildingDir.path);
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Bangunan'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$buildingName"?\n\nTindakan ini akan menghapus semua data (ruangan/denah) di dalamnya.',
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
        await buildingDir.delete(recursive: true);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bangunan "$buildingName" berhasil dihapus.'),
            ),
          );
        await _loadBuildings();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus bangunan: $e')),
          );
      }
    }
  }

  void _editBuilding(Directory buildingDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomEditorPage(buildingDirectory: buildingDir),
      ),
    );
  }

  void _viewDistrictMap() {
    CloudNavigation.push(
      context,
      DistrictMapViewerPage(districtDirectory: widget.districtDirectory),
    );
  }

  void _openMapEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) =>
            DistrictMapEditorPage(districtDirectory: widget.districtDirectory),
      ),
    );
  }

  // --- HELPER UTILS ---

  Future<Map<String, dynamic>> _getBuildingIconData(
    Directory buildingDir,
  ) async {
    try {
      final jsonFile = File(p.join(buildingDir.path, 'data.json'));
      if (!await jsonFile.exists()) return {'type': null, 'data': null};
      final content = await jsonFile.readAsString();
      final data = json.decode(content);
      final iconType = data.containsKey('icon_type') ? data['icon_type'] : null;
      final iconData = data.containsKey('icon_data') ? data['icon_data'] : null;
      if (iconType == 'image' && iconData != null) {
        final imageFile = File(p.join(buildingDir.path, iconData.toString()));
        if (await imageFile.exists())
          return {'type': 'image', 'data': iconData, 'file': imageFile};
        else
          return {'type': null, 'data': null};
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

  @override
  Widget build(BuildContext context) {
    final districtName = p.basename(widget.districtDirectory.path);

    return Scaffold(
      appBar: AppBar(
        title: Text('Distrik: $districtName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Lihat Peta Distrik',
            onPressed: _viewDistrictMap,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuildings,
            tooltip: 'Muat Ulang Daftar',
          ),
        ],
      ),
      body: _buildBody(),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabOpen) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Edit Peta",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'map_editor',
                  onPressed: () {
                    _openMapEditor();
                    setState(() => _isFabOpen = false);
                  },
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.map, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Buat Bangunan",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'add_building',
                  onPressed: () {
                    _showCreateBuildingDialog();
                    setState(() => _isFabOpen = false);
                  },
                  child: const Icon(Icons.add_business),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: 'main_toggle',
            onPressed: () => setState(() => _isFabOpen = !_isFabOpen),
            child: Icon(_isFabOpen ? Icons.close : Icons.apps),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_buildingFolders.isEmpty)
      return const Center(
        child: Text(
          'Distrik ini belum memiliki bangunan.\nTekan tombol menu di bawah untuk memulai.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 150),
      itemCount: _buildingFolders.length,
      itemBuilder: (context, index) {
        final folder = _buildingFolders[index];
        final folderName = p.basename(folder.path);

        return ListTile(
          leading: FutureBuilder<Map<String, dynamic>>(
            future: _getBuildingIconData(folder),
            key: ValueKey(folder.path),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              if (!snapshot.hasData)
                return _buildIconContainer(const Icon(Icons.location_city));
              final type = snapshot.data!['type'];
              final data = snapshot.data!['data'];
              final imageFile = snapshot.data!['file'] as File?;
              if (type == 'text' && data != null)
                return _buildIconContainer(
                  Text(
                    data.toString(),
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                );
              if (type == 'image' && imageFile != null)
                return _buildIconContainer(null, imageFile: imageFile);
              return _buildIconContainer(const Icon(Icons.location_city));
            },
          ),
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'view') _viewBuilding(folder);
              if (v == 'edit_room') _editBuilding(folder);
              if (v == 'edit_info') _showEditBuildingDialog(folder);
              if (v == 'move') _moveBuilding(folder);
              if (v == 'retract') _retractBuilding(folder);
              if (v == 'export_icon') _exportBuildingIcon(folder);
              if (v == 'delete') _deleteBuilding(folder);
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Lihat / Masuk'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_room',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Edit Ruangan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Pindahkan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'retract',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Simpan ke Bank'),
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
                value: 'export_icon',
                child: Row(
                  children: [
                    Icon(Icons.ios_share, color: Colors.indigo),
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
          onTap: () => _viewBuilding(folder),
        );
      },
    );
  }
}
