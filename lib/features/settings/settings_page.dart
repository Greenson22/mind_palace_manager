// lib/features/settings/settings_page.dart
// ... (Imports)
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:mind_palace_manager/app_settings.dart';

import 'package:mind_palace_manager/features/settings/sections/general_settings_section.dart';
import 'package:mind_palace_manager/features/settings/sections/visualization_settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ... (Controller declarations)
  late TextEditingController _folderController;
  late TextEditingController _exportPathController;

  // ... (Visualization State declarations)
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

  late bool _defaultShowObjectIcons;
  late double _objectIconOpacity;
  late bool _interactableWhenHidden;

  // ... (General State declarations)
  late String _currentWallpaperFit;
  late String _currentWallpaperMode;
  late Color _currentSolidColor;
  late Color _currentGradientColor1;
  late Color _currentGradientColor2;
  late double _currentBlurStrength;
  late double _currentOverlayOpacity;

  // --- SLIDESHOW STATE ---
  late double _slideshowSpeed;
  late double _slideshowTransitionDuration;
  String _selectedSlideshowContentName =
      'Pilih Sumber'; // Rename variabel agar general
  Directory? _selectedSlideshowContentDir; // Rename variabel

  @override
  void initState() {
    super.initState();
    _folderController = TextEditingController(
      text: AppSettings.baseBuildingsPath ?? 'Belum diatur',
    );
    _exportPathController = TextEditingController(
      text: AppSettings.exportPath ?? 'Belum diatur',
    );

    _loadAllStates();
  }

  void _loadAllStates() {
    // ... (Load Visualization States)
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

    _defaultShowObjectIcons = AppSettings.defaultShowObjectIcons;
    _objectIconOpacity = AppSettings.objectIconOpacity;
    _interactableWhenHidden = AppSettings.interactableWhenHidden;

    _currentWallpaperFit = AppSettings.wallpaperFit;
    _currentWallpaperMode = AppSettings.wallpaperMode;
    _currentSolidColor = Color(AppSettings.solidColor.value);
    _currentGradientColor1 = Color(AppSettings.gradientColor1);
    _currentGradientColor2 = Color(AppSettings.gradientColor2);
    _currentBlurStrength = AppSettings.blurStrength.value;

    // --- PERUBAHAN DI SINI: Menambahkan .value ---
    _currentOverlayOpacity = AppSettings.backgroundOverlayOpacity.value;

    _slideshowSpeed = AppSettings.slideshowSpeedSeconds;
    _slideshowTransitionDuration =
        AppSettings.slideshowTransitionDurationSeconds;

    if (AppSettings.slideshowBuildingPath != null) {
      _selectedSlideshowContentDir = Directory(
        AppSettings.slideshowBuildingPath!,
      );
      // Nama Distrik atau Bangunan
      _selectedSlideshowContentName = p.basename(
        AppSettings.slideshowBuildingPath!,
      );
      if (AppSettings.slideshowSourceType == 'district') {
        _selectedSlideshowContentName =
            "[Distrik] $_selectedSlideshowContentName";
      }
    } else {
      _selectedSlideshowContentDir = null;
      _selectedSlideshowContentName = 'Pilih Sumber';
    }
  }

  @override
  void dispose() {
    _folderController.dispose();
    _exportPathController.dispose();
    super.dispose();
  }

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
            selectedSlideshowBuildingName:
                _selectedSlideshowContentName, // Pass general name
            selectedSlideshowBuildingDir: _selectedSlideshowContentDir,
            slideshowSpeed: _slideshowSpeed,
            slideshowTransitionDuration: _slideshowTransitionDuration,
            currentSolidColor: _currentSolidColor,
            currentGradientColor1: _currentGradientColor1,
            currentGradientColor2: _currentGradientColor2,
            currentBlurStrength: _currentBlurStrength,
            currentOverlayOpacity: _currentOverlayOpacity,
            setStateCallback: _updateSettingsState,
          ),

          const SizedBox(height: 24),

          // --- 2. Visualization & Other Settings Section ---
          // (Tetap sama, tidak ada perubahan)
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
            defaultShowObjectIcons: _defaultShowObjectIcons,
            objectIconOpacity: _objectIconOpacity,
            interactableWhenHidden: _interactableWhenHidden,
            setStateCallback: _updateSettingsState,
          ),
        ],
      ),
    );
  }
}
