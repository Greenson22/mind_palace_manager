// lib/features/settings/sections/general_settings_section.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/widgets/settings_helpers.dart';
import 'package:mind_palace_manager/features/settings/dialogs/wallpaper_manager_dialogs.dart';

// --- IMPORT HALAMAN BACKUP (Pastikan file ini sudah dibuat) ---
import 'package:mind_palace_manager/features/settings/backup_page.dart';

class GeneralSettingsSection extends StatelessWidget {
  final TextEditingController folderController;
  final TextEditingController exportPathController;
  final String currentWallpaperFit;
  final String currentWallpaperMode;

  final String selectedSlideshowBuildingName;
  final Directory? selectedSlideshowBuildingDir;
  final double slideshowSpeed;
  final double slideshowTransitionDuration;
  final Color currentSolidColor;
  final Color currentGradientColor1;
  final Color currentGradientColor2;
  final double currentBlurStrength;

  final double currentOverlayOpacity;

  final Function(VoidCallback fn) setStateCallback;

  const GeneralSettingsSection({
    super.key,
    required this.folderController,
    required this.exportPathController,
    required this.currentWallpaperFit,
    required this.currentWallpaperMode,
    required this.selectedSlideshowBuildingName,
    required this.selectedSlideshowBuildingDir,
    required this.slideshowSpeed,
    required this.slideshowTransitionDuration,
    required this.currentSolidColor,
    required this.currentGradientColor1,
    required this.currentGradientColor2,
    required this.currentBlurStrength,
    required this.currentOverlayOpacity,
    required this.setStateCallback,
  });

  Future<void> _pickAndCreateFolder(BuildContext context) async {
    // 1. Biarkan pengguna memilih folder induk (misal: Documents)
    String? selectedPath = await FilePicker.platform.getDirectoryPath();

    if (selectedPath != null) {
      try {
        // 2. Modifikasi path dengan menambahkan /.buildings di belakangnya
        final String hiddenPath = p.join(selectedPath, '.buildings');
        final rootDir = Directory(hiddenPath);

        // 3. Buat direktori .buildings jika belum ada
        if (!await rootDir.exists()) {
          await rootDir.create(recursive: true);
        }

        // 4. Simpan path yang berakhiran .buildings ke pengaturan
        await AppSettings.saveBaseBuildingsPath(rootDir.path);

        setStateCallback(() {
          folderController.text = AppSettings.baseBuildingsPath!;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Folder penyimpanan berhasil diatur (Sub-folder .buildings dibuat).',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  Future<void> _pickAndSaveExportFolder(BuildContext context) async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath != null) {
      try {
        final exportDir = Directory(selectedPath);
        await AppSettings.saveExportPath(exportDir.path);
        setStateCallback(() {
          exportPathController.text = AppSettings.exportPath!;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Folder export peta berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Inisialisasi WallpaperManagerDialogs
    final dialogs = WallpaperManagerDialogs(
      context: context,
      setStateCallback: setStateCallback,
      selectedSlideshowBuildingName: selectedSlideshowBuildingName,
      selectedSlideshowBuildingDir: selectedSlideshowBuildingDir,
      slideshowSpeed: slideshowSpeed,
      slideshowTransitionDuration: slideshowTransitionDuration,
      currentSolidColor: currentSolidColor,
      currentGradientColor1: currentGradientColor1,
      currentGradientColor2: currentGradientColor2,
      currentBlurStrength: currentBlurStrength,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(context, 'Umum'),
        buildSettingsCard([
          ListTile(
            leading: Icon(Icons.brightness_6, color: primaryColor),
            title: const Text('Tema Aplikasi'),
            subtitle: Text(getThemeModeLabel(AppSettings.themeMode.value)),
            trailing: DropdownButton<ThemeMode>(
              value: AppSettings.themeMode.value,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down_circle_outlined),
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  setStateCallback(() {
                    AppSettings.saveThemeMode(newValue);
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistem'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Terang')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Gelap')),
              ],
            ),
          ),

          const Divider(indent: 56),
          ListTile(
            leading: Icon(Icons.wallpaper, color: primaryColor),
            title: const Text('Atur Wallpaper Dashboard'),
            subtitle: Text(
              getWallpaperModeLabel(
                currentWallpaperMode,
                selectedSlideshowBuildingName,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: ElevatedButton(
              onPressed: dialogs.showWallpaperSelectionDialog,
              child: const Text('Pilih / Atur'),
            ),
          ),

          const Divider(indent: 56),
          ListTile(
            leading: Icon(Icons.aspect_ratio, color: primaryColor),
            title: const Text('Mode Tampilan Wallpaper'),
            trailing: buildBoxFitDropdown(
              context: context,
              value: currentWallpaperFit,
              onChanged: (val) async {
                if (val != null) {
                  await AppSettings.saveWallpaperFit(val);
                  setStateCallback(() {});
                }
              },
            ),
          ),

          const Divider(indent: 56),
          buildSliderTile(
            icon: Icons.opacity,
            color: primaryColor,
            title: 'Transparansi Cover',
            value: currentOverlayOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (val) async {
              await AppSettings.saveBackgroundOverlayOpacity(val);
              setStateCallback(() {});
            },
          ),

          const Divider(indent: 56),
          ListTile(
            leading: Icon(Icons.folder_open, color: primaryColor),
            title: const Text('Lokasi Penyimpanan'),
            subtitle: Text(
              folderController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.drive_file_move_outline),
              onPressed: () => _pickAndCreateFolder(context),
              tooltip: 'Ubah Folder',
            ),
          ),

          const Divider(indent: 56),
          ListTile(
            leading: Icon(Icons.save_alt, color: primaryColor),
            title: const Text('Lokasi Export Peta'),
            subtitle: Text(
              exportPathController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () => _pickAndSaveExportFolder(context),
              tooltip: 'Ubah Folder Export',
            ),
          ),

          // --- FITUR BACKUP & RESTORE (BARU) ---
          const Divider(indent: 56),
          ListTile(
            leading: Icon(Icons.backup, color: primaryColor),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Cadangkan atau pulihkan data (.zip)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const BackupPage()),
              );
            },
          ),
        ]),
      ],
    );
  }
}
