// lib/features/settings/dialogs/wallpaper_manager_dialogs.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/app_settings.dart';
// Import kelas helper baru
import 'package:mind_palace_manager/features/settings/dialogs/wallpaper_sub_dialogs.dart';

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
  double currentBlurStrength; // <-- FIX: Mengubah tipe data ke double

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

  // Fungsi yang dipertahankan: Memilih gambar statis dari galeri
  Future<void> _pickImageFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      await AppSettings.saveStaticWallpaper(result.files.single.path!);
      setStateCallback(() {});
    }
  }

  // --- MAIN DIALOG (Bottom Sheet) ---
  void showWallpaperSelectionDialog() {
    // Inisialisasi helper dialog
    final subDialogs = WallpaperSubDialogs(
      context: context,
      setStateCallback: setStateCallback,
      slideshowSpeed: slideshowSpeed,
      slideshowTransitionDuration: slideshowTransitionDuration,
      currentSolidColor: currentSolidColor,
      currentGradientColor1: currentGradientColor1,
      currentGradientColor2: currentGradientColor2,
      currentBlurStrength: currentBlurStrength, // Sekarang bertipe double
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          // PERBAIKAN: Membungkus konten dengan SingleChildScrollView untuk mencegah overflow
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
                    subDialogs.showBackgroundSolidDialog(); // Delegasi
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.gradient, color: Colors.indigo),
                  title: const Text('Gradient'),
                  onTap: () {
                    Navigator.pop(context);
                    subDialogs.showBackgroundGradientDialog(); // Delegasi
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
                    subDialogs.showSlideshowBuildingPicker(); // Delegasi
                  },
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih Gambar Statis dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery(); // Dipertahankan di kelas ini
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.meeting_room),
                  title: const Text('Pilih Gambar Ruangan Statis (Bangunan)'),
                  onTap: () {
                    Navigator.pop(context);
                    subDialogs.showStaticRoomPicker(); // Delegasi
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Pilih Ikon Bangunan/Distrik Statis'),
                  onTap: () {
                    Navigator.pop(context);
                    subDialogs.showIconPicker(); // Delegasi
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
                    subDialogs.showBlurSettingsDialog(); // Delegasi
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
      // Pastikan state parent di-update setelah dialog ditutup
      setStateCallback(() {});
    });
  }
}
