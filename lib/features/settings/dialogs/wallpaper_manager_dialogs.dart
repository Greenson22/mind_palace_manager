// lib/features/settings/dialogs/wallpaper_manager_dialogs.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/widgets/settings_helpers.dart';
import 'package:mind_palace_manager/features/settings/dialogs/color_picker_dialog.dart';

// Class yang memegang semua logika dan dialog terkait Wallpaper
class WallpaperManagerDialogs {
  final BuildContext context;
  final Function(VoidCallback fn)
  setStateCallback; // Callback untuk update state di SettingsPage
  final String selectedSlideshowBuildingName;
  final Directory? selectedSlideshowBuildingDir;

  // State lokal untuk dialog Slideshow/Solid/Gradient/Blur (nilai saat ini dari SettingsPage)
  double slideshowSpeed;
  double slideshowTransitionDuration;
  Color currentSolidColor;
  Color currentGradientColor1;
  Color currentGradientColor2;
  double currentBlurStrength;

  WallpaperManagerDialogs({
    required this.context,
    required this.setStateCallback,
    required this.selectedSlideshowBuildingName,
    required this.selectedSlideshowBuildingDir,
    required this.slideshowSpeed,
    required this.slideshowTransitionDuration,
    required this.currentSolidColor,
    required this.currentGradientColor1,
    required this.currentGradientColor2,
    required this.currentBlurStrength,
  });

  // --- FUNGSI _getWallpaperModeLabel DIHAPUS, DIGANTIKAN OLEH HELPER PUBLIK ---

  Widget _buildBuildingIconContainer(
    String? iconType,
    dynamic iconData,
    String buildingPath,
  ) {
    // Fungsi ini harus dimuat dari file lain jika ingin dimurnikan sepenuhnya,
    // namun karena ini adalah helper traversal kompleks, saya menyimpannya di sini
    // untuk menjaga kode tetap utuh, dan hanya memanggil helper UI sederhana.
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

    // Menggunakan helper dari settings_helpers
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

  // --- LOGIKA TRAVERSAL (dipindahkan dari settings_page.dart) ---

  Future<List<ImageSourceInfo>> _loadAllIconImages() async {
    final List<ImageSourceInfo> images = [];
    if (AppSettings.baseBuildingsPath == null) return images;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    if (!await rootDir.exists()) return images;

    await for (final regionEntity in rootDir.list()) {
      if (regionEntity is Directory) {
        final regionName = p.basename(regionEntity.path);

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
                images.add(ImageSourceInfo(iconPath, 'Wilayah: $regionName'));
              }
            }
          } catch (_) {}
        }

        await for (final districtEntity in regionEntity.list()) {
          if (districtEntity is Directory) {
            final districtName = p.basename(districtEntity.path);

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
                      ImageSourceInfo(iconPath, 'Distrik: $districtName'),
                    );
                  }
                }
              } catch (_) {}
            }

            await for (final buildingEntity in districtEntity.list()) {
              if (buildingEntity is Directory) {
                final buildingDataFile = File(
                  p.join(buildingEntity.path, 'data.json'),
                );

                if (!await buildingDataFile.exists()) continue;

                try {
                  final content = await buildingDataFile.readAsString();
                  Map<String, dynamic> buildingData = json.decode(content);

                  if (buildingData['icon_type'] == 'image' &&
                      buildingData['icon_data'] != null) {
                    final iconPath = p.join(
                      buildingEntity.path,
                      buildingData['icon_data'],
                    );
                    if (await File(iconPath).exists()) {
                      images.add(
                        ImageSourceInfo(
                          iconPath,
                          'Bangunan: ${p.basename(buildingEntity.path)}',
                        ),
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

  Future<List<BuildingInfo>> _loadAllBuildingsWithRooms() async {
    final List<BuildingInfo> result = [];
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
                      BuildingInfo(
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

  Future<List<ImageSourceInfo>> _loadRoomImagesFromBuilding(
    Directory buildingDir,
  ) async {
    final List<ImageSourceInfo> images = [];
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
              ImageSourceInfo(
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

  // --- SELESAI LOGIKA TRAVERSAL ---

  // --- DIALOGS ---

  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      await AppSettings.saveStaticWallpaper(result.files.single.path!);
      setStateCallback(() {});
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
    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;
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
                    if (context.mounted) {
                      Navigator.pop(c);
                      setStateCallback(() {});
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
    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;
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
    if (context.mounted) Navigator.pop(context);

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
                    if (context.mounted) {
                      Navigator.pop(c);
                      setStateCallback(() {});
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
    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;
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

    final List<BuildingInfo> slideshowReadyBuildings = [];
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
                    Navigator.pop(c);
                    _showSlideshowSettingsDialog(info.directory, info.name);
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

  Future<void> _showSlideshowSettingsDialog(
    Directory buildingDir,
    String buildingName,
  ) async {
    // Gunakan state lokal dan update state parent di akhir
    double tempSpeed = slideshowSpeed;
    double tempTransition = slideshowTransitionDuration;

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Pengaturan Slideshow (${buildingName})'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kecepatan Ganti Ruangan (detik)'),
                    Slider(
                      value: tempSpeed,
                      min: 3.0,
                      max: 60.0,
                      divisions: 57,
                      label: tempSpeed.toStringAsFixed(0),
                      onChanged: (val) => setDialogState(() => tempSpeed = val),
                    ),
                    Text('Saat ini: ${tempSpeed.toStringAsFixed(0)} detik'),

                    const Divider(),

                    const Text('Durasi Transisi (detik)'),
                    Slider(
                      value: tempTransition,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      label: tempTransition.toStringAsFixed(1),
                      onChanged: (val) =>
                          setDialogState(() => tempTransition = val),
                    ),
                    Text(
                      'Saat ini: ${tempTransition.toStringAsFixed(1)} detik',
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
                    await AppSettings.saveSlideshowSettings(
                      buildingPath: buildingDir.path,
                      speed: tempSpeed,
                      transitionDuration: tempTransition,
                    );
                    if (context.mounted) {
                      Navigator.pop(c);
                      setStateCallback(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Slideshow Bangunan "${buildingName}" diaktifkan.',
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

  Future<void> _showBackgroundSolidDialog() async {
    Color tempSolidColor = currentSolidColor;

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
                  buildColorCircle(
                    tempSolidColor,
                    () => showColorPickerDialog(
                      context,
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
                    if (context.mounted) {
                      Navigator.pop(c);
                      setStateCallback(() {});
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
    Color tempColor1 = currentGradientColor1;
    Color tempColor2 = currentGradientColor2;

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
                  buildColorCircle(
                    tempColor1,
                    () => showColorPickerDialog(
                      context,
                      'Pilih Warna Awal',
                      tempColor1,
                      (color) => setDialogState(() => tempColor1 = color),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Warna Akhir:'),
                  buildColorCircle(
                    tempColor2,
                    () => showColorPickerDialog(
                      context,
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
                    if (context.mounted) {
                      Navigator.pop(c);
                      setStateCallback(() {});
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

    double tempBlurStrength = currentBlurStrength;

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
                    if (context.mounted) {
                      Navigator.pop(c);
                      setStateCallback(() {});
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
  void showWallpaperSelectionDialog() {
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

              ListTile(
                leading: const Icon(Icons.slideshow, color: Colors.purple),
                title: const Text('Slideshow Ruangan (Bangunan)'),
                subtitle: Text(
                  // Menggunakan selectedSlideshowBuildingName dari state
                  AppSettings.wallpaperMode == 'slideshow'
                      ? 'Bangunan: ${selectedSlideshowBuildingName} (${AppSettings.slideshowSpeedSeconds.toStringAsFixed(0)}s)'
                      : 'Pilih bangunan untuk slideshow',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSlideshowBuildingPicker();
                },
              ),
              const Divider(height: 1),

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

              ListTile(
                leading: const Icon(Icons.blur_on, color: Colors.teal),
                title: Text(
                  'Atur Efek Blur (${currentBlurStrength.toStringAsFixed(1)})',
                ),
                subtitle: const Text('Berlaku untuk mode Gambar/Slideshow'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlurSettingsDialog();
                },
              ),

              if (AppSettings.wallpaperMode != 'default')
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: const Text('Hapus Wallpaper/Background'),
                  onTap: () async {
                    Navigator.pop(context);
                    await AppSettings.clearWallpaper();
                    setStateCallback(() {});
                  },
                ),
            ],
          ),
        );
      },
    ).then((_) {
      // Pastikan state parent di-update setelah dialog ditutup
      setStateCallback(() {});
    });
  }
}
