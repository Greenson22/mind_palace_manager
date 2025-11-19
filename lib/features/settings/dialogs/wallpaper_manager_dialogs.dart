// lib/features/settings/dialogs/wallpaper_manager_dialogs.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/dialogs/wallpaper_sub_dialogs.dart';

class WallpaperManagerDialogs {
  final BuildContext context;
  final Function(VoidCallback fn) setStateCallback;
  final String
  selectedSlideshowBuildingName; // Ini sekarang jadi label umum (Bangunan/Distrik)
  final Directory? selectedSlideshowBuildingDir;

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

  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      await AppSettings.saveStaticWallpaper(result.files.single.path!);
      setStateCallback(() {});
    }
  }

  void showWallpaperSelectionDialog() {
    final subDialogs = WallpaperSubDialogs(
      context: context,
      setStateCallback: setStateCallback,
      slideshowSpeed: slideshowSpeed,
      slideshowTransitionDuration: slideshowTransitionDuration,
      currentSolidColor: currentSolidColor,
      currentGradientColor1: currentGradientColor1,
      currentGradientColor2: currentGradientColor2,
      currentBlurStrength: currentBlurStrength,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
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
                    subDialogs.showBackgroundSolidDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.gradient, color: Colors.indigo),
                  title: const Text('Gradient'),
                  onTap: () {
                    Navigator.pop(context);
                    subDialogs.showBackgroundGradientDialog();
                  },
                ),
                const Divider(height: 1),

                // --- OPSI SLIDESHOW BANGUNAN ---
                ListTile(
                  leading: const Icon(Icons.slideshow, color: Colors.purple),
                  title: const Text('Slideshow Ruangan (Bangunan)'),
                  subtitle: Text(
                    (AppSettings.wallpaperMode == 'slideshow' &&
                            AppSettings.slideshowSourceType == 'building')
                        ? 'Aktif: ${selectedSlideshowBuildingName} (${AppSettings.slideshowSpeedSeconds.toStringAsFixed(0)}s)'
                        : 'Pilih bangunan untuk slideshow',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    subDialogs.showSlideshowBuildingPicker();
                  },
                ),

                // --- BARU: OPSI SLIDESHOW DISTRIK ---
                ListTile(
                  leading: const Icon(
                    Icons.photo_album,
                    color: Colors.deepPurple,
                  ),
                  title: const Text('Slideshow Ruangan (Distrik)'),
                  subtitle: Text(
                    (AppSettings.wallpaperMode == 'slideshow' &&
                            AppSettings.slideshowSourceType == 'district')
                        ? 'Aktif: ${selectedSlideshowBuildingName} (${AppSettings.slideshowSpeedSeconds.toStringAsFixed(0)}s)'
                        : 'Pilih distrik untuk slideshow',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    subDialogs.showSlideshowDistrictPicker();
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
                    subDialogs.showStaticRoomPicker();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Pilih Ikon Bangunan/Distrik Statis'),
                  onTap: () {
                    Navigator.pop(context);
                    subDialogs.showIconPicker();
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
                    subDialogs.showBlurSettingsDialog();
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
          ),
        );
      },
    ).then((_) {
      setStateCallback(() {});
    });
  }
}
