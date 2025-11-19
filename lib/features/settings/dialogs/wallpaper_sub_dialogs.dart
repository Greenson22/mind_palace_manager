// lib/features/settings/dialogs/wallpaper_sub_dialogs.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/widgets/settings_helpers.dart'; // Untuk buildColorCircle
import 'package:mind_palace_manager/features/settings/dialogs/color_picker_dialog.dart';
import 'package:mind_palace_manager/features/settings/helpers/wallpaper_image_loader.dart'; // Traversal logic

class WallpaperSubDialogs {
  final BuildContext context;
  final Function(VoidCallback fn) setStateCallback;

  // State Slideshow/Solid/Gradient/Blur dari SettingsPage
  double slideshowSpeed;
  double slideshowTransitionDuration;
  Color currentSolidColor;
  Color currentGradientColor1;
  Color currentGradientColor2;
  double currentBlurStrength; // <-- Tipe data sudah benar: double

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

  // --- 1. ICON PICKER ---
  Future<void> showIconPicker() async {
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

    // Tampilkan loading
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

  // --- 2. STATIC ROOM PICKER (Langkah 1: Pilih Bangunan) ---
  Future<void> showStaticRoomPicker() async {
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

    // Tampilkan loading
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

  // --- 3. STATIC ROOM PICKER (Langkah 2: Pilih Ruangan) ---
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

  // --- 4. SLIDESHOW PICKER (Langkah 1: Pilih Bangunan) ---
  Future<void> showSlideshowBuildingPicker() async {
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

    // Tampilkan loading
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

    final buildingList = await WallpaperImageLoader.loadAllBuildingsWithRooms();
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

    // Filter bangunan yang memiliki minimal 2 gambar ruangan
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

  // --- 5. SLIDESHOW SETTINGS DIALOG (Langkah 2: Atur Pengaturan) ---
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

  // --- 6. SOLID COLOR DIALOG ---
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

  // --- 7. GRADIENT DIALOG ---
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

  // --- 8. BLUR SETTINGS DIALOG ---
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
