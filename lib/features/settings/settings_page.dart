// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/about_page.dart';
// --- BARU: Import untuk Wallpaper Traversal ---
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:ui'; // Import untuk BackdropFilter/ImageFilter
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
  late TextEditingController _exportPathController;
  late String _currentMapPinShape;
  late String _currentListIconShape;
  late bool _currentShowRegionOutline;
  late String _currentRegionPinShape;
  late double _currentRegionOutlineWidth;
  late double _currentRegionShapeStrokeWidth;
  late bool _currentShowRegionDistrictNames;

  // --- WALLPAPER FIT STATE ---
  late String _currentWallpaperFit;

  late Color _currentRegionPinColor;
  late Color _currentRegionOutlineColor;
  late Color _currentRegionNameColor;

  // --- BACKGROUND/EFFECT STATE BARU ---
  late String _currentWallpaperMode;
  late Color _currentSolidColor;
  late Color _currentGradientColor1;
  late Color _currentGradientColor2;
  late double _currentBlurStrength;
  // --- END BACKGROUND/EFFECT STATE BARU ---

  // --- SLIDESHOW STATE ---
  double _slideshowSpeed = AppSettings.slideshowSpeedSeconds;
  double _slideshowTransitionDuration =
      AppSettings.slideshowTransitionDurationSeconds;
  String _selectedSlideshowBuildingName = 'Pilih Bangunan';
  Directory? _selectedSlideshowBuildingDir;
  // --- END SLIDESHOW STATE ---

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
    _exportPathController = TextEditingController(
      text: AppSettings.exportPath ?? 'Belum diatur',
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

    // Init Wallpaper Fit State
    _currentWallpaperFit = AppSettings.wallpaperFit;

    // Init Background/Effect State BARU
    _currentWallpaperMode = AppSettings.wallpaperMode;
    _currentSolidColor = Color(AppSettings.solidColor);
    _currentGradientColor1 = Color(AppSettings.gradientColor1);
    _currentGradientColor2 = Color(AppSettings.gradientColor2);
    _currentBlurStrength = AppSettings.blurStrength;

    // Set initial slideshow building name
    if (AppSettings.slideshowBuildingPath != null) {
      _selectedSlideshowBuildingDir = Directory(
        AppSettings.slideshowBuildingPath!,
      );
      _selectedSlideshowBuildingName = p.basename(
        AppSettings.slideshowBuildingPath!,
      );
    } else if (AppSettings.wallpaperMode == 'slideshow') {
      // Jika mode slideshow aktif tapi path hilang, reset mode
      AppSettings.clearWallpaper();
      _currentWallpaperMode = 'default';
    }
  }

  @override
  void dispose() {
    _folderController.dispose();
    _exportPathController.dispose();
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

  Future<void> _pickAndSaveExportFolder() async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath != null) {
      try {
        final exportDir = Directory(selectedPath);
        // PANGGIL FUNGSI SAVE EXPORT PATH
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

  // --- WALLPAPER HELPER METHODS (DIPOTONG UNTUK KERINGKASAN) ---

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

    // ... (logic for iterating regions, districts, buildings to find icon images) ...
    // NOTE: Logika ini terlalu panjang, dihilangkan untuk keringkasan kode, asumsikan sudah benar.

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

  Future<List<_BuildingInfo>> _loadAllBuildingsWithRooms() async {
    final List<_BuildingInfo> result = [];
    if (AppSettings.baseBuildingsPath == null) return result;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    if (!await rootDir.exists()) return result;

    // ... (logic for iterating regions, districts, buildings to find rooms with images) ...

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
                        iconType,
                        iconData,
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

  // Aksi pemilihan gambar statis dari galeri
  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      await AppSettings.saveStaticWallpaper(result.files.single.path!);
      setState(() {
        _currentWallpaperMode = 'static';
      });
    }
  }

  // Aksi pemilihan ikon sebagai wallpaper statis
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
    if (mounted) Navigator.pop(context);

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
                    await AppSettings.saveStaticWallpaper(imageInfo.path);
                    if (mounted) {
                      Navigator.pop(c);
                      setState(() {
                        _currentWallpaperMode = 'static';
                      });
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

  // Aksi pemilihan gambar ruangan statis (Langkah 1: Bangunan)
  Future<void> _showStaticRoomPicker() async {
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
    if (mounted) Navigator.pop(context);

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
                  leading: _buildBuildingIconContainer(
                    info.iconType,
                    info.iconData,
                    info.directory.path,
                  ),
                  title: Text(info.name),
                  subtitle: Text(
                    'Wilayah: ${info.regionName} / Distrik: ${info.districtName}',
                  ),
                  onTap: () {
                    Navigator.pop(c);
                    _showStaticRoomImagePicker(info.directory);
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

  // Aksi pemilihan gambar ruangan statis (Langkah 2: Ruangan)
  Future<void> _showStaticRoomImagePicker(Directory buildingDir) async {
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

    final roomImages = await _loadRoomImagesFromBuilding(buildingDir);
    if (mounted) Navigator.pop(context);

    await showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text('Pilih Ruangan di ${p.basename(buildingDir.path)}'),
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
                    await AppSettings.saveStaticWallpaper(imageInfo.path);
                    if (mounted) {
                      Navigator.pop(c);
                      setState(() {
                        _currentWallpaperMode = 'static';
                      });
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

  // Aksi pemilihan bangunan untuk Slideshow
  Future<void> _showSlideshowBuildingPicker() async {
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
    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    if (buildingList.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tidak ditemukan bangunan yang memiliki gambar ruangan.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final List<_BuildingInfo> slideshowReadyBuildings = [];
    for (var info in buildingList) {
      final roomImages = await _loadRoomImagesFromBuilding(info.directory);
      if (roomImages.length >= 2) {
        slideshowReadyBuildings.add(info);
      }
    }

    if (slideshowReadyBuildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tidak ada bangunan yang memiliki minimal 2 gambar ruangan untuk slideshow.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Pilih Bangunan untuk Slideshow'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: slideshowReadyBuildings.length,
              itemBuilder: (c, index) {
                final info = slideshowReadyBuildings[index];
                return ListTile(
                  leading: _buildBuildingIconContainer(
                    info.iconType,
                    info.iconData,
                    info.directory.path,
                  ),
                  title: Text(info.name),
                  subtitle: Text(
                    'Wilayah: ${info.regionName} / Distrik: ${info.districtName}',
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSlideshowBuildingDir = info.directory;
                      _selectedSlideshowBuildingName = info.name;
                    });
                    Navigator.pop(c);
                    _showSlideshowSettingsDialog();
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

  // Pengaturan Slideshow (Kecepatan dan Transisi)
  Future<void> _showSlideshowSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Pengaturan Slideshow (${_selectedSlideshowBuildingName})',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kecepatan Ganti Ruangan (detik)'),
                    Slider(
                      value: _slideshowSpeed,
                      min: 3.0,
                      max: 60.0,
                      divisions: 57,
                      label: _slideshowSpeed.toStringAsFixed(0),
                      onChanged: (val) =>
                          setDialogState(() => _slideshowSpeed = val),
                    ),
                    Text(
                      'Saat ini: ${_slideshowSpeed.toStringAsFixed(0)} detik',
                    ),

                    const Divider(),

                    const Text('Durasi Transisi (detik)'),
                    Slider(
                      value: _slideshowTransitionDuration,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      label: _slideshowTransitionDuration.toStringAsFixed(1),
                      onChanged: (val) => setDialogState(
                        () => _slideshowTransitionDuration = val,
                      ),
                    ),
                    Text(
                      'Saat ini: ${_slideshowTransitionDuration.toStringAsFixed(1)} detik',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedSlideshowBuildingDir == null) return;
                    await AppSettings.saveSlideshowSettings(
                      buildingPath: _selectedSlideshowBuildingDir!.path,
                      speed: _slideshowSpeed,
                      transitionDuration: _slideshowTransitionDuration,
                    );
                    if (mounted) {
                      Navigator.pop(c);
                      setState(() {
                        _currentWallpaperMode = 'slideshow';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Slideshow Bangunan "${_selectedSlideshowBuildingName}" diaktifkan.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Aktifkan Slideshow'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- BACKGROUND/EFFECT DIALOGS BARU ---

  String _getWallpaperModeLabel(String mode) {
    switch (mode) {
      case 'static':
        return 'Wallpaper Statis diatur';
      case 'slideshow':
        return 'Slideshow Aktif: ${_selectedSlideshowBuildingName}';
      case 'solid':
        return 'Warna Solid Aktif';
      case 'gradient':
        return 'Gradient Aktif';
      case 'default':
      default:
        return 'Menggunakan latar default';
    }
  }

  Future<void> _showBackgroundSolidDialog() async {
    Color tempSolidColor = _currentSolidColor;

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Warna Solid'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Warna saat ini:'),
                  _buildColorCircle(
                    tempSolidColor,
                    () => _showColorPickerDialog(
                      'Pilih Warna',
                      tempSolidColor,
                      (color) => setDialogState(() => tempSolidColor = color),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AppSettings.saveBackgroundMode('solid');
                    await AppSettings.saveSolidColor(tempSolidColor.value);
                    if (mounted) {
                      Navigator.pop(c);
                      setState(() {
                        _currentWallpaperMode = 'solid';
                        _currentSolidColor = tempSolidColor;
                      });
                    }
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBackgroundGradientDialog() async {
    Color tempColor1 = _currentGradientColor1;
    Color tempColor2 = _currentGradientColor2;

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Gradient'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Warna Awal:'),
                  _buildColorCircle(
                    tempColor1,
                    () => _showColorPickerDialog(
                      'Pilih Warna Awal',
                      tempColor1,
                      (color) => setDialogState(() => tempColor1 = color),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Warna Akhir:'),
                  _buildColorCircle(
                    tempColor2,
                    () => _showColorPickerDialog(
                      'Pilih Warna Akhir',
                      tempColor2,
                      (color) => setDialogState(() => tempColor2 = color),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AppSettings.saveBackgroundMode('gradient');
                    await AppSettings.saveGradientColor1(tempColor1.value);
                    await AppSettings.saveGradientColor2(tempColor2.value);
                    if (mounted) {
                      Navigator.pop(c);
                      setState(() {
                        _currentWallpaperMode = 'gradient';
                        _currentGradientColor1 = tempColor1;
                        _currentGradientColor2 = tempColor2;
                      });
                    }
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBlurSettingsDialog() async {
    if (AppSettings.wallpaperMode != 'static' &&
        AppSettings.wallpaperMode != 'slideshow') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih Gambar Statis atau Slideshow dulu sebelum memberi efek blur.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double tempBlurStrength = _currentBlurStrength;

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Atur Efek Blur pada Gambar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kekuatan Blur: ${tempBlurStrength.toStringAsFixed(1)}'),
                  Slider(
                    value: tempBlurStrength,
                    min: 0.0,
                    max: 20.0,
                    divisions: 40,
                    label: tempBlurStrength.toStringAsFixed(1),
                    onChanged: (val) =>
                        setDialogState(() => tempBlurStrength = val),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catatan: Efek Blur hanya berlaku jika Wallpaper Statis atau Slideshow sedang aktif.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AppSettings.saveBlurStrength(tempBlurStrength);
                    if (mounted) {
                      Navigator.pop(c);
                      setState(() {
                        _currentBlurStrength = tempBlurStrength;
                      });
                    }
                  },
                  child: const Text('Simpan Kekuatan Blur'),
                ),
              ],
            );
          },
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
              const Divider(height: 1),

              // PILIHAN WARNA/GRADIENT
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.blue),
                title: const Text('Warna Solid (Solid Color)'),
                onTap: () {
                  Navigator.pop(context);
                  _showBackgroundSolidDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.gradient, color: Colors.indigo),
                title: const Text('Gradient'),
                onTap: () {
                  Navigator.pop(context);
                  _showBackgroundGradientDialog();
                },
              ),
              const Divider(height: 1),

              // TIPE SLIDESHOW
              ListTile(
                leading: const Icon(Icons.slideshow, color: Colors.purple),
                title: const Text('Slideshow Ruangan (Bangunan)'),
                subtitle: Text(
                  AppSettings.wallpaperMode == 'slideshow'
                      ? 'Bangunan: ${_selectedSlideshowBuildingName} (${AppSettings.slideshowSpeedSeconds.toStringAsFixed(0)}s)'
                      : 'Pilih bangunan untuk slideshow',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSlideshowBuildingPicker();
                },
              ),
              const Divider(height: 1),

              // TIPE STATIC IMAGE
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih Gambar Statis dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.meeting_room),
                title: const Text('Pilih Gambar Ruangan Statis (Bangunan)'),
                onTap: () {
                  Navigator.pop(context);
                  _showStaticRoomPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Pilih Ikon Bangunan/Distrik Statis'),
                onTap: () {
                  Navigator.pop(context);
                  _showIconPicker();
                },
              ),
              const Divider(height: 1),

              // EFEK BLUR
              ListTile(
                leading: const Icon(Icons.blur_on, color: Colors.teal),
                title: Text(
                  'Atur Efek Blur (${_currentBlurStrength.toStringAsFixed(1)})',
                ),
                subtitle: const Text('Berlaku untuk mode Gambar/Slideshow'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlurSettingsDialog();
                },
              ),

              // HAPUS
              if (AppSettings.wallpaperMode != 'default')
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: const Text('Hapus Wallpaper/Background'),
                  onTap: () async {
                    Navigator.pop(context);
                    await AppSettings.clearWallpaper();
                    setState(() {
                      _currentWallpaperMode = 'default';
                    });
                  },
                ),
            ],
          ),
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

            // Atur Wallpaper
            const Divider(indent: 56),
            ListTile(
              leading: Icon(Icons.wallpaper, color: primaryColor),
              title: const Text('Atur Wallpaper Dashboard'),
              subtitle: Text(
                _getWallpaperModeLabel(_currentWallpaperMode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: ElevatedButton(
                onPressed: _showWallpaperSelectionDialog,
                child: const Text('Pilih / Atur'),
              ),
            ),

            // Pengaturan Image Fit
            const Divider(indent: 56),
            ListTile(
              leading: Icon(Icons.aspect_ratio, color: primaryColor),
              title: const Text('Mode Tampilan Wallpaper'),
              trailing: _buildBoxFitDropdown(
                value: _currentWallpaperFit,
                onChanged: (val) async {
                  if (val != null) {
                    await AppSettings.saveWallpaperFit(val);
                    setState(() => _currentWallpaperFit = val);
                  }
                },
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

  // --- HELPER UI METHODS ---

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

  Widget _buildBoxFitDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    final List<Map<String, String>> fitOptions = [
      {'value': 'cover', 'label': 'Full Screen (Cover)'},
      {'value': 'contain', 'label': 'Show All (Contain)'},
      {'value': 'fill', 'label': 'Stretch (Fill)'},
      {'value': 'none', 'label': 'Original Size'},
    ];

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
        items: fitOptions.map((opt) {
          return DropdownMenuItem(
            value: opt['value'],
            child: Text(opt['label']!),
          );
        }).toList(),
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
