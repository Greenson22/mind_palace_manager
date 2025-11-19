// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/about_page.dart';
// --- BARU: Import untuk Wallpaper Traversal ---
import 'package:path/path.dart' as p;
import 'dart:convert';
// --- SELESAI BARU ---

// --- BARU: Class helper untuk menyimpan info gambar ---
class _ImageSourceInfo {
  final String path;
  final String label;
  final String? buildingPath; // Ditambahkan untuk hierarki ruangan
  _ImageSourceInfo(this.path, this.label, {this.buildingPath});
}

class _BuildingInfo {
  final Directory directory;
  final String name;
  final String districtName;
  final String regionName;
  final String? iconType;
  final dynamic iconData;
  _BuildingInfo(
    this.directory,
    this.name,
    this.districtName,
    this.regionName,
    this.iconType,
    this.iconData,
  );
}
// --- SELESAI BARU ---

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _folderController;
  late TextEditingController _exportPathController; // DIBUAT BARU
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
    // --- BARU: Inisialisasi Export Path Controller ---
    _exportPathController = TextEditingController(
      text: AppSettings.exportPath ?? 'Belum diatur',
    );
    // --- SELESAI BARU ---
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
    // --- BARU: Dispose Export Path Controller ---
    _exportPathController.dispose();
    // --- SELESAI BARU ---
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

  // --- Fungsi untuk memilih dan menyimpan folder export ---
  Future<void> _pickAndSaveExportFolder() async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath != null) {
      try {
        final exportDir = Directory(selectedPath);
        await AppSettings.saveExportPath(exportDir.path);
        setState(() {
          _exportPathController.text = AppSettings.exportPath!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Folder export peta berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengatur folder export: $e'),
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

  // --- START LOGIKA WALLPAPER ---

  // Helper untuk merender ikon bangunan berdasarkan data
  Widget _buildBuildingIconContainer(
    String? iconType,
    dynamic iconData,
    String buildingPath,
  ) {
    double size = 40.0;
    Widget child = const Icon(Icons.location_city, size: 24);
    File? imageFile;

    if (iconType == 'text' &&
        iconData != null &&
        iconData.toString().isNotEmpty) {
      child = Text(
        iconData.toString(),
        style: const TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      );
    } else if (iconType == 'image' && iconData != null) {
      final path = p.join(buildingPath, iconData.toString());
      final file = File(path);
      if (file.existsSync()) {
        imageFile = file;
      }
    }

    // Gunakan logika listIconShape (Bulat/Kotak/Tanpa Latar)
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

  // Traversal untuk mengumpulkan gambar ikon dari semua tingkatan
  Future<List<_ImageSourceInfo>> _loadAllIconImages() async {
    final List<_ImageSourceInfo> images = [];
    if (AppSettings.baseBuildingsPath == null) return images;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);

    if (!await rootDir.exists()) return images;

    await for (final regionEntity in rootDir.list()) {
      if (regionEntity is Directory) {
        final regionName = p.basename(regionEntity.path);

        // Region Icons
        final regionDataFile = File(
          p.join(regionEntity.path, 'region_data.json'),
        );
        if (await regionDataFile.exists()) {
          try {
            final content = await regionDataFile.readAsString();
            final data = json.decode(content);
            if (data['icon_type'] == 'image' && data['icon_data'] != null) {
              final iconPath = p.join(regionEntity.path, data['icon_data']);
              if (await File(iconPath).exists()) {
                images.add(_ImageSourceInfo(iconPath, 'Wilayah: $regionName'));
              }
            }
          } catch (_) {}
        }

        await for (final districtEntity in regionEntity.list()) {
          if (districtEntity is Directory) {
            final districtName = p.basename(districtEntity.path);

            // District Icons
            final districtDataFile = File(
              p.join(districtEntity.path, 'district_data.json'),
            );
            if (await districtDataFile.exists()) {
              try {
                final content = await districtDataFile.readAsString();
                final data = json.decode(content);
                if (data['icon_type'] == 'image' && data['icon_data'] != null) {
                  final iconPath = p.join(
                    districtEntity.path,
                    data['icon_data'],
                  );
                  if (await File(iconPath).exists()) {
                    images.add(
                      _ImageSourceInfo(iconPath, 'Distrik: $districtName'),
                    );
                  }
                }
              } catch (_) {}
            }

            await for (final buildingEntity in districtEntity.list()) {
              if (buildingEntity is Directory) {
                final buildingName = p.basename(buildingEntity.path);
                final buildingDataFile = File(
                  p.join(buildingEntity.path, 'data.json'),
                );

                if (!await buildingDataFile.exists()) continue;

                try {
                  final content = await buildingDataFile.readAsString();
                  Map<String, dynamic> buildingData = json.decode(content);

                  // Building Icons
                  if (buildingData['icon_type'] == 'image' &&
                      buildingData['icon_data'] != null) {
                    final iconPath = p.join(
                      buildingEntity.path,
                      buildingData['icon_data'],
                    );
                    if (await File(iconPath).exists()) {
                      images.add(
                        _ImageSourceInfo(iconPath, 'Bangunan: $buildingName'),
                      );
                    }
                  }
                } catch (_) {}
              }
            }
          }
        }
      }
    }
    return images;
  }

  // Traversal untuk mengumpulkan bangunan yang memiliki gambar ruangan
  Future<List<_BuildingInfo>> _loadAllBuildingsWithRooms() async {
    final List<_BuildingInfo> result = [];
    if (AppSettings.baseBuildingsPath == null) return result;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    if (!await rootDir.exists()) return result;

    await for (final regionEntity in rootDir.list()) {
      if (regionEntity is Directory) {
        final regionName = p.basename(regionEntity.path);
        await for (final districtEntity in regionEntity.list()) {
          if (districtEntity is Directory) {
            final districtName = p.basename(districtEntity.path);
            await for (final buildingEntity in districtEntity.list()) {
              if (buildingEntity is Directory) {
                final buildingName = p.basename(buildingEntity.path);
                final buildingDataFile = File(
                  p.join(buildingEntity.path, 'data.json'),
                );

                if (!await buildingDataFile.exists()) continue;

                try {
                  final content = await buildingDataFile.readAsString();
                  Map<String, dynamic> buildingData = json.decode(content);

                  final iconType = buildingData['icon_type'];
                  final iconData = buildingData['icon_data'];

                  // Cek apakah ada setidaknya satu gambar ruangan
                  List<dynamic> rooms = buildingData['rooms'] ?? [];
                  bool hasRoomImage = rooms.any((room) {
                    if (room['image'] != null) {
                      final imagePath = p.join(
                        buildingEntity.path,
                        room['image'],
                      );
                      return File(imagePath).existsSync();
                    }
                    return false;
                  });

                  if (hasRoomImage) {
                    result.add(
                      _BuildingInfo(
                        buildingEntity,
                        buildingName,
                        districtName,
                        regionName,
                        iconType, // NEW
                        iconData, // NEW
                      ),
                    );
                  }
                } catch (_) {}
              }
            }
          }
        }
      }
    }
    return result;
  }

  // Traversal untuk memuat gambar ruangan spesifik dari satu bangunan
  Future<List<_ImageSourceInfo>> _loadRoomImagesFromBuilding(
    Directory buildingDir,
  ) async {
    final List<_ImageSourceInfo> images = [];
    final buildingDataFile = File(p.join(buildingDir.path, 'data.json'));
    if (!await buildingDataFile.exists()) return images;

    try {
      final content = await buildingDataFile.readAsString();
      Map<String, dynamic> buildingData = json.decode(content);
      List<dynamic> rooms = buildingData['rooms'] ?? [];

      for (var room in rooms) {
        if (room['image'] != null) {
          final relativeImagePath = room['image'];
          final imagePath = p.join(buildingDir.path, relativeImagePath);
          if (await File(imagePath).exists()) {
            // NOTE: imagePath di sini sudah path absolut
            images.add(
              _ImageSourceInfo(
                imagePath,
                room['name'] ?? 'Tanpa Nama',
                buildingPath: buildingDir.path,
              ),
            );
          }
        }
      }
    } catch (_) {}

    return images;
  }

  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      await AppSettings.saveWallpaperPath(result.files.single.path!);
      setState(() {});
    }
  }

  Future<void> _showIconPicker() async {
    if (AppSettings.baseBuildingsPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Atur lokasi penyimpanan utama di Pengaturan terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Memuat ikon..."),
          ],
        ),
      ),
    );

    final images = await _loadAllIconImages();
    if (mounted) Navigator.pop(context); // Dismiss loading

    if (!mounted) return;
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ditemukan ikon bangunan/distrik."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Pilih Ikon Bangunan/Distrik'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: GridView.builder(
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (c, index) {
                final imageInfo = images[index];
                return GestureDetector(
                  onTap: () async {
                    await AppSettings.saveWallpaperPath(imageInfo.path);
                    if (mounted) {
                      Navigator.pop(c);
                      setState(() {});
                    }
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(imageInfo.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          imageInfo.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // --- HIERARCHICAL PICKER FOR ROOMS (STEP 1: BUILDING) ---
  Future<void> _showBuildingPicker() async {
    if (AppSettings.baseBuildingsPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Atur lokasi penyimpanan utama di Pengaturan terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Memuat bangunan dengan gambar ruangan..."),
          ],
        ),
      ),
    );

    final buildingList = await _loadAllBuildingsWithRooms();
    if (mounted) Navigator.pop(context); // Dismiss loading

    if (!mounted) return;
    if (buildingList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ditemukan bangunan yang berisi gambar ruangan."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Show Building Picker Dialog
    await showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Pilih Bangunan (Langkah 1/2)'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: buildingList.length,
              itemBuilder: (c, index) {
                final info = buildingList[index];
                return ListTile(
                  // --- BARU: Tambahkan leading icon ---
                  leading: _buildBuildingIconContainer(
                    info.iconType,
                    info.iconData,
                    info.directory.path,
                  ),
                  // --- SELESAI BARU ---
                  title: Text(info.name),
                  subtitle: Text(
                    'Wilayah: ${info.regionName} / Distrik: ${info.districtName}',
                  ),
                  onTap: () {
                    Navigator.pop(c); // Tutup picker bangunan
                    _showRoomPicker(info); // Lanjut ke picker ruangan
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // --- HIERARCHICAL PICKER FOR ROOMS (STEP 2: ROOM) ---
  Future<void> _showRoomPicker(_BuildingInfo buildingInfo) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Memuat ruangan..."),
          ],
        ),
      ),
    );

    final roomImages = await _loadRoomImagesFromBuilding(
      buildingInfo.directory,
    );
    if (mounted) Navigator.pop(context); // Dismiss loading

    await showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text('Pilih Ruangan di ${buildingInfo.name}'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: GridView.builder(
              itemCount: roomImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (c, index) {
                final imageInfo = roomImages[index];

                return GestureDetector(
                  onTap: () async {
                    // imageInfo.path sudah merupakan path absolut
                    await AppSettings.saveWallpaperPath(imageInfo.path);
                    if (mounted) {
                      Navigator.pop(c); // Close room picker
                      setState(() {});
                    }
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(imageInfo.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          imageInfo.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // --- MAIN DIALOG (Bottom Sheet) ---
  Future<void> _showWallpaperSelectionDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Pilih Sumber Wallpaper',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.meeting_room),
                title: const Text('Pilih Gambar Ruangan (Bangunan)'),
                onTap: () {
                  Navigator.pop(context);
                  _showBuildingPicker(); // Memulai alur hierarkis
                },
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Pilih Ikon Bangunan/Distrik'),
                onTap: () {
                  Navigator.pop(context);
                  _showIconPicker();
                },
              ),
              if (AppSettings.wallpaperPath != null)
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: const Text('Hapus Wallpaper'),
                  onTap: () async {
                    Navigator.pop(context);
                    await AppSettings.saveWallpaperPath(null);
                    setState(() {});
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- END LOGIKA WALLPAPER ---

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

            // --- BARU: Atur Wallpaper ---
            const Divider(indent: 56),
            ListTile(
              leading: Icon(Icons.wallpaper, color: primaryColor),
              title: const Text('Atur Wallpaper Dashboard'),
              subtitle: Text(
                AppSettings.wallpaperPath != null
                    ? 'Wallpaper diatur'
                    : 'Menggunakan latar default',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // FIX ERROR: Mengubah 'showWallpaperSelectionDialog' menjadi '_showWallpaperSelectionDialog'
              trailing: ElevatedButton(
                onPressed: _showWallpaperSelectionDialog,
                child: const Text('Pilih'),
              ),
            ),

            // --- SELESAI BARU ---
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
                icon: const Icon(Icons.drive_file_move_outline),
                onPressed: _pickAndCreateFolder,
                tooltip: 'Ubah Folder',
              ),
            ),

            const Divider(indent: 56),
            ListTile(
              leading: Icon(Icons.save_alt, color: primaryColor),
              title: const Text('Lokasi Export Peta'),
              subtitle: Text(
                _exportPathController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _pickAndSaveExportFolder,
                tooltip: 'Ubah Folder Export',
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

  // --- START HELPER UI METHODS (DIPERBAIKI) ---

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

  // --- END HELPER UI METHODS ---
}
