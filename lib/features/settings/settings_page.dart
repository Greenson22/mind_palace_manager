// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/about_page.dart';
// --- BARU: Import Sections ---
import 'package:mind_palace_manager/features/settings/sections/general_settings_section.dart';
import 'package:mind_palace_manager/features/settings/sections/visualization_settings_section.dart';
// --- SELESAI BARU ---

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- Text Controllers ---
  late TextEditingController _folderController;
  late TextEditingController _exportPathController;

  // --- State Visualisasi Peta ---
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

  // --- State Umum / Wallpaper ---
  late String _currentWallpaperFit;
  late String _currentWallpaperMode;
  late Color _currentSolidColor;
  late Color _currentGradientColor1;
  late Color _currentGradientColor2;
  late double _currentBlurStrength; // <-- FIX: Mengubah tipe data ke double

  // --- SLIDESHOW STATE ---
  late double _slideshowSpeed;
  late double _slideshowTransitionDuration;
  String _selectedSlideshowBuildingName = 'Pilih Bangunan';
  Directory? _selectedSlideshowBuildingDir;

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
    _exportPathController = TextEditingController(
      text: AppSettings.exportPath ?? 'Belum diatur',
    );

    // --- Inisialisasi Semua State dari AppSettings ---
    _loadAllStates();
  }

  // Helper untuk memuat/memuat ulang semua state dari AppSettings
  void _loadAllStates() {
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

    _currentWallpaperFit = AppSettings.wallpaperFit;

    _currentWallpaperMode = AppSettings.wallpaperMode;
    _currentSolidColor = Color(AppSettings.solidColor);
    _currentGradientColor1 = Color(AppSettings.gradientColor1);
    _currentGradientColor2 = Color(AppSettings.gradientColor2);
    _currentBlurStrength = AppSettings.blurStrength; // Memuat double
    _slideshowSpeed = AppSettings.slideshowSpeedSeconds;
    _slideshowTransitionDuration =
        AppSettings.slideshowTransitionDurationSeconds;

    if (AppSettings.slideshowBuildingPath != null) {
      _selectedSlideshowBuildingDir = Directory(
        AppSettings.slideshowBuildingPath!,
      );
      _selectedSlideshowBuildingName = p.basename(
        AppSettings.slideshowBuildingPath!,
      );
    } else {
      _selectedSlideshowBuildingDir = null;
      _selectedSlideshowBuildingName = 'Pilih Bangunan';
    }
  }

  @override
  void dispose() {
    _folderController.dispose();
    _exportPathController.dispose();
    super.dispose();
  }

  // Fungsi setter untuk mengupdate state dari widget anak dan memuat ulang semua data
  void _updateSettingsState(VoidCallback fn) {
    setState(() {
      fn();
      _loadAllStates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 1. General Settings Section ---
          GeneralSettingsSection(
            folderController: _folderController,
            exportPathController: _exportPathController,
            currentWallpaperFit: _currentWallpaperFit,
            currentWallpaperMode: _currentWallpaperMode,

            // State untuk dialog Wallpaper Manager
            selectedSlideshowBuildingName: _selectedSlideshowBuildingName,
            selectedSlideshowBuildingDir: _selectedSlideshowBuildingDir,
            slideshowSpeed: _slideshowSpeed,
            slideshowTransitionDuration: _slideshowTransitionDuration,
            currentSolidColor: _currentSolidColor,
            currentGradientColor1: _currentGradientColor1,
            currentGradientColor2: _currentGradientColor2,
            currentBlurStrength: _currentBlurStrength,
            setStateCallback: _updateSettingsState,
          ),

          const SizedBox(height: 24),

          // --- 2. Visualization & Other Settings Section ---
          VisualizationSettingsSection(
            currentMapPinShape: _currentMapPinShape,
            currentRegionPinShape: _currentRegionPinShape,
            currentShowRegionOutline: _currentShowRegionOutline,
            currentRegionOutlineWidth: _currentRegionOutlineWidth,
            currentRegionShapeStrokeWidth: _currentRegionShapeStrokeWidth,
            currentShowRegionDistrictNames: _currentShowRegionDistrictNames,
            currentRegionPinColor: _currentRegionPinColor,
            currentRegionOutlineColor: _currentRegionOutlineColor,
            currentRegionNameColor: _currentRegionNameColor,
            currentListIconShape: _currentListIconShape,
            setStateCallback: _updateSettingsState,
          ),
        ],
      ),
    );
  }
}
