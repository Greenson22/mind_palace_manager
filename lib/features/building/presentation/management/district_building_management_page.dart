// lib/features/building/presentation/management/district_building_management_page.dart
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

class DistrictBuildingManagementPage extends StatefulWidget {
  // Menerima path distrik yang dipilih
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

  // --- State untuk dialog Buat / Edit ---
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _buildingIconTextController =
      TextEditingController();
  String _buildingIconType = 'Default'; // Tipe: 'Default', 'Teks', 'Gambar'
  String? _buildingIconImagePath;

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
    setState(() {
      _isLoading = true;
    });

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

    // Path 'base' sekarang adalah path distrik
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

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showCreateBuildingDialog() async {
    // Reset state dialog untuk 'Buat Baru'
    _buildingNameController.clear();
    _buildingIconTextController.clear();
    _buildingIconType = 'Default';
    _buildingIconImagePath = null;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // Gunakan StatefulBuilder agar dialog bisa update UI-nya sendiri
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
                    const SizedBox(height: 24),
                    Text(
                      'Ikon Bangunan (Opsional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    DropdownButton<String>(
                      value: _buildingIconType,
                      isExpanded: true,
                      items: ['Default', 'Teks', 'Gambar'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _buildingIconType = newValue!;
                        });
                      },
                    ),

                    // Tampilkan input berdasarkan Tipe Ikon
                    if (_buildingIconType == 'Teks')
                      TextField(
                        controller: _buildingIconTextController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan 1-2 karakter (cth: 🏠 atau A)',
                        ),
                        maxLength: 2,
                      ),

                    if (_buildingIconType == 'Gambar')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                setDialogState(() {
                                  _buildingIconImagePath =
                                      result.files.single.path!;
                                });
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Buat'),
                  // Cek nama bangunan saat dialog sedang aktif
                  onPressed: () {
                    if (_buildingNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama bangunan tidak boleh kosong.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      _createNewBuilding();
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

    // Tentukan data ikon
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
        // Gambar harus disalin ke folder bangunan BARU
        iconType = 'image';
        iconData = p.basename(_buildingIconImagePath!);
      }

      // Buat folder bangunan
      final newBuildingPath = p.join(
        widget.districtDirectory.path,
        buildingName,
      );
      final newDir = Directory(newBuildingPath);
      await newDir.create(recursive: true);

      // Salin gambar ikon jika ada
      if (iconType == 'image' && _buildingIconImagePath != null) {
        final sourceFile = File(_buildingIconImagePath!);
        final destinationPath = p.join(newBuildingPath, iconData);
        await sourceFile.copy(destinationPath);
      }

      // Buat file data.json dengan info ikon
      final dataJsonFile = File(p.join(newBuildingPath, 'data.json'));
      final jsonData = {
        "icon_type": iconType,
        "icon_data": iconData,
        "rooms": [],
      };
      await dataJsonFile.writeAsString(json.encode(jsonData));

      if (mounted) {
        Navigator.of(context).pop();
      }
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

  Future<void> _showEditIconDialog(Directory buildingDir) async {
    // 1. Muat data ikon saat ini
    final iconData = await _getBuildingIconData(buildingDir);
    String currentType = iconData['type'] ?? 'Default';
    dynamic currentData = iconData['data'];

    // 2. Atur state dialog
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

    // 3. Tampilkan dialog
    final bool? didSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String currentImageText = '...';
            if (_buildingIconType == 'Gambar' && currentType == 'image') {
              currentImageText =
                  'Gambar saat ini: "$currentData"\n(Pilih file baru untuk mengganti)';
            } else if (_buildingIconType == 'Gambar' &&
                _buildingIconImagePath != null) {
              currentImageText =
                  'File baru: ${p.basename(_buildingIconImagePath!)}';
            } else {
              currentImageText = 'Pilih Gambar Ikon';
            }

            return AlertDialog(
              title: Text('Ganti Ikon: ${p.basename(buildingDir.path)}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ikon Bangunan',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    DropdownButton<String>(
                      value: _buildingIconType,
                      isExpanded: true,
                      items: ['Default', 'Teks', 'Gambar'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _buildingIconType = newValue!;
                        });
                      },
                    ),
                    if (_buildingIconType == 'Teks')
                      TextField(
                        controller: _buildingIconTextController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan 1-2 karakter (cth: 🏠 atau A)',
                        ),
                        maxLength: 2,
                      ),
                    if (_buildingIconType == 'Gambar')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                setDialogState(() {
                                  _buildingIconImagePath =
                                      result.files.single.path!;
                                });
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
                    await _updateBuildingIcon(buildingDir);
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop(true); // Kirim 'true' jika disimpan
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    // 4. Segarkan (refresh) UI jika pengguna menekan 'Simpan'
    if (didSave == true) {
      setState(() {
        // Memaksa UI untuk membangun ulang dan
        // FutureBuilder di _buildBody akan mengambil data ikon baru
      });
    }
  }

  Future<void> _updateBuildingIcon(Directory buildingDir) async {
    final jsonFile = File(p.join(buildingDir.path, 'data.json'));
    Map<String, dynamic> jsonData;

    // 1. Baca data.json yang ada
    try {
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        jsonData = json.decode(content);
      } else {
        jsonData = {"rooms": []};
      }
    } catch (e) {
      jsonData = {"rooms": []}; // Gagal parse, buat baru
    }

    // 2. Tentukan data ikon baru
    String? iconType;
    dynamic iconData;
    String? oldImageName = jsonData['icon_type'] == 'image'
        ? jsonData['icon_data']
        : null;

    if (_buildingIconType == 'Teks') {
      iconType = 'text';
      iconData = _buildingIconTextController.text.trim();
      if (iconData.isEmpty) {
        iconType = null;
        iconData = null;
      }
    } else if (_buildingIconType == 'Gambar') {
      if (_buildingIconImagePath != null) {
        // Pengguna memilih gambar baru
        iconType = 'image';
        iconData = p.basename(_buildingIconImagePath!);
        try {
          // Salin file baru ke folder bangunan
          final sourceFile = File(_buildingIconImagePath!);
          final destinationPath = p.join(buildingDir.path, iconData);
          await sourceFile.copy(destinationPath);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyalin gambar baru: $e')),
            );
          }
          return; // Batalkan penyimpanan jika salin gagal
        }
      } else if (oldImageName != null) {
        // Pengguna tidak memilih gambar baru, TAPI tipe tetap 'Gambar'
        // Pertahankan gambar lama
        iconType = 'image';
        iconData = oldImageName;
      } else {
        iconType = null;
        iconData = null;
      }
    } else {
      // Tipe 'Default'
      iconType = null;
      iconData = null;
    }

    if (oldImageName != null &&
        (iconType != 'image' || iconData != oldImageName)) {
      try {
        final oldImageFile = File(p.join(buildingDir.path, oldImageName));
        if (await oldImageFile.exists()) {
          await oldImageFile.delete();
        }
      } catch (e) {
        print("Gagal menghapus gambar ikon lama: $e");
      }
    }

    // 3. Perbarui JSON
    jsonData['icon_type'] = iconType;
    jsonData['icon_data'] = iconData;

    // 4. Simpan kembali
    try {
      await jsonFile.writeAsString(json.encode(jsonData));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ikon berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan ikon: $e')));
      }
    }
  }

  void _viewBuilding(Directory buildingDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BuildingViewerPage(buildingDirectory: buildingDir),
      ),
    );
  }

  void _editBuilding(Directory buildingDir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomEditorPage(buildingDirectory: buildingDir),
      ),
    );
  }

  Future<void> _deleteBuilding(Directory buildingDir) async {
    final buildingName = p.basename(buildingDir.path);

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Bangunan'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$buildingName"?\n\n'
            'Tindakan ini akan menghapus semua folder, ruangan, dan gambar di dalamnya secara permanen.',
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bangunan "$buildingName" berhasil dihapus.'),
            ),
          );
        }
        await _loadBuildings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus bangunan: $e')),
          );
        }
      }
    }
  }

  void _viewDistrictMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DistrictMapViewerPage(districtDirectory: widget.districtDirectory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan nama distrik di AppBar
    final districtName = p.basename(widget.districtDirectory.path);

    return Scaffold(
      appBar: AppBar(
        title: Text('Distrik: $districtName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: _viewDistrictMap,
            tooltip: 'Lihat Peta Distrik',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuildings,
            tooltip: 'Muat Ulang Daftar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBuildingDialog,
        tooltip: 'Buat Bangunan Baru',
        child: const Icon(Icons.add_business),
      ),
    );
  }

  /// Membaca data.json dari folder bangunan untuk mendapatkan info ikon.
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

      return {'type': iconType, 'data': iconData};
    } catch (e) {
      print('Gagal membaca ikon: $e');
      return {'type': null, 'data': null};
    }
  }

  // --- FUNGSI HELPER DIPERBARUI ---
  /// Membangun kontainer ikon berdasarkan pengaturan global
  Widget _buildIconContainer(Widget? child, {File? imageFile}) {
    double size = 40.0; // Ukuran standar leading ListTile

    // --- BACA PENGATURAN BARU ---
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
        // Sesuai permintaan: "benar-benar hanya foto sendiri"
        // Kita gunakan SizedBox untuk memastikan alignment daftar tetap rapi
        return SizedBox(
          width: size,
          height: size,
          child: imageFile != null
              ? Image.file(
                  imageFile,
                  fit: BoxFit.contain, // Contain agar gambar tidak terpotong
                  errorBuilder: (c, e, s) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                )
              : Center(child: child), // Teks/Ikon tetap di tengah
        );
    }
  }
  // --- SELESAI FUNGSI HELPER ---

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buildingFolders.isEmpty) {
      return const Center(
        child: Text(
          'Distrik ini belum memiliki bangunan.\nKlik tombol + untuk membuat yang baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _buildingFolders.length,
      itemBuilder: (context, index) {
        final folder = _buildingFolders[index];
        final folderName = p.basename(folder.path);

        // --- Widget Ikon Dinamis (DIPERBARUI) ---
        final Widget leadingIcon = FutureBuilder<Map<String, dynamic>>(
          future: _getBuildingIconData(folder),
          key: ValueKey(folder.path),
          builder: (context, snapshot) {
            // Saat memuat
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildIconContainer(
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            // Jika error atau tidak ada data
            if (!snapshot.hasData || snapshot.hasError) {
              return _buildIconContainer(const Icon(Icons.location_city));
            }

            final type = snapshot.data!['type'];
            final data = snapshot.data!['data'];

            // Tipe Teks
            if (type == 'text' && data != null && data.toString().isNotEmpty) {
              return _buildIconContainer(
                Text(
                  data.toString(),
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              );
            }

            // Tipe Gambar
            if (type == 'image' && data != null) {
              final imageFile = File(p.join(folder.path, data.toString()));
              return _buildIconContainer(null, imageFile: imageFile);
            }

            // Fallback (Default)
            return _buildIconContainer(const Icon(Icons.location_city));
          },
        );
        // --- Selesai Widget Ikon ---

        return ListTile(
          leading: leadingIcon,
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(folder.path, style: const TextStyle(fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.palette_outlined, color: Colors.blue),
                tooltip: 'Ganti Ikon',
                onPressed: () => _showEditIconDialog(folder),
              ),
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: 'Lihat',
                onPressed: () => _viewBuilding(folder),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Ruangan',
                onPressed: () => _editBuilding(folder),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Hapus',
                onPressed: () => _deleteBuilding(folder),
              ),
            ],
          ),
          onTap: null,
        );
      },
    );
  }
}
