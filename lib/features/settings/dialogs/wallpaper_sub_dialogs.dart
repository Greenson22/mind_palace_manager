// lib/features/settings/dialogs/wallpaper_sub_dialogs.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/widgets/settings_helpers.dart';
import 'package:mind_palace_manager/features/settings/dialogs/color_picker_dialog.dart';
import 'package:mind_palace_manager/features/settings/helpers/wallpaper_image_loader.dart';

class WallpaperSubDialogs {
  final BuildContext context;
  final Function(VoidCallback fn) setStateCallback;

  double slideshowSpeed;
  double slideshowTransitionDuration;
  Color currentSolidColor;
  Color currentGradientColor1;
  Color currentGradientColor2;
  double currentBlurStrength;

  WallpaperSubDialogs({
    required this.context,
    required this.setStateCallback,
    required this.slideshowSpeed,
    required this.slideshowTransitionDuration,
    required this.currentSolidColor,
    required this.currentGradientColor1,
    required this.currentGradientColor2,
    required this.currentBlurStrength,
  });

  // ... showIconPicker, showStaticRoomPicker, _showStaticRoomImagePicker TETAP SAMA ...
  Future<void> showIconPicker() async {
    // (Kode lama...)
    // Untuk ringkasnya saya tidak tulis ulang karena tidak berubah
    // Anda bisa menyalin dari file sebelumnya jika perlu, atau biarkan bagian ini
    // Intinya hanya menambahkan fungsi baru di bawah.
    // Agar aman, saya akan salin fungsi penting yang berubah dan fungsi baru.
    // Asumsikan fungsi pick statis tidak berubah.
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

    final images = await WallpaperImageLoader.loadAllIconImages();
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

  Future<void> showStaticRoomPicker() async {
    // (Kode lama showStaticRoomPicker tetap sama)
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
            Text("Memuat bangunan..."),
          ],
        ),
      ),
    );

    final buildingList = await WallpaperImageLoader.loadAllBuildingsWithRooms();
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
                  leading: WallpaperImageLoader.buildBuildingListIcon(
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
    // (Kode lama _showStaticRoomImagePicker tetap sama)
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

    final roomImages = await WallpaperImageLoader.loadRoomImagesFromBuilding(
      buildingDir,
    );
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

  // --- 4. SLIDESHOW PICKER (BANGUNAN) ---
  Future<void> showSlideshowBuildingPicker() async {
    // (Kode lama showSlideshowBuildingPicker tetap sama)
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
            Text("Memuat bangunan..."),
          ],
        ),
      ),
    );

    final buildingList = await WallpaperImageLoader.loadAllBuildingsWithRooms();
    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;
    if (buildingList.isEmpty) {
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

    // Filter
    final List<BuildingInfo> slideshowReadyBuildings = [];
    for (var info in buildingList) {
      final roomImages = await WallpaperImageLoader.loadRoomImagesFromBuilding(
        info.directory,
      );
      if (roomImages.length >= 2) {
        slideshowReadyBuildings.add(info);
      }
    }

    if (slideshowReadyBuildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tidak ada bangunan yang memiliki minimal 2 gambar ruangan.",
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
                  leading: WallpaperImageLoader.buildBuildingListIcon(
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
                    _showSlideshowSettingsDialog(
                      info.directory,
                      info.name,
                      'building', // Source Type
                    );
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

  // --- BARU: SLIDESHOW PICKER (DISTRIK) ---
  Future<void> showSlideshowDistrictPicker() async {
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
            Text("Memuat distrik..."),
          ],
        ),
      ),
    );

    // Memuat distrik yang punya bangunan
    final districtList = await WallpaperImageLoader.loadAllDistrictsWithRooms();
    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;
    if (districtList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tidak ditemukan distrik yang memiliki bangunan dengan gambar.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Filter distrik yang punya minimal 2 gambar total
    final List<DistrictInfo> slideshowReadyDistricts = [];
    for (var info in districtList) {
      final roomImages = await WallpaperImageLoader.loadRoomImagesFromDistrict(
        info.directory,
      );
      if (roomImages.length >= 2) {
        slideshowReadyDistricts.add(info);
      }
    }

    if (slideshowReadyDistricts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tidak ada distrik yang memiliki minimal 2 gambar ruangan total.",
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
          title: const Text('Pilih Distrik untuk Slideshow'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: slideshowReadyDistricts.length,
              itemBuilder: (c, index) {
                final info = slideshowReadyDistricts[index];
                return ListTile(
                  leading: const Icon(Icons.map, size: 32, color: Colors.blue),
                  title: Text(info.name),
                  subtitle: Text(
                    'Wilayah: ${info.regionName} (${info.buildingCount} Bangunan)',
                  ),
                  onTap: () {
                    Navigator.pop(c);
                    _showSlideshowSettingsDialog(
                      info.directory,
                      info.name,
                      'district', // Source Type
                    );
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

  // --- UPDATE: SLIDESHOW SETTINGS DIALOG ---
  Future<void> _showSlideshowSettingsDialog(
    Directory sourceDir, // Bangunan atau Distrik
    String sourceName,
    String sourceType,
  ) async {
    double tempSpeed = slideshowSpeed;
    double tempTransition = slideshowTransitionDuration;

    await showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Pengaturan Slideshow ($sourceName)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kecepatan Ganti Gambar (detik)'),
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
                      path: sourceDir.path,
                      sourceType: sourceType,
                      speed: tempSpeed,
                      transitionDuration: tempTransition,
                    );
                    if (context.mounted) {
                      Navigator.pop(c);
                      setStateCallback(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Slideshow ${sourceType == 'building' ? 'Bangunan' : 'Distrik'} "$sourceName" diaktifkan.',
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

  // ... (Dialog Solid, Gradient, Blur tetap sama) ...
  Future<void> showBackgroundSolidDialog() async {
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

  Future<void> showBackgroundGradientDialog() async {
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

  Future<void> showBlurSettingsDialog() async {
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
}
