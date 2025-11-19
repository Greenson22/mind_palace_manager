// lib/app_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // --- KEYS ---
  static const String _basePathKey = 'baseBuildingsPath';
  static const String _mapPinShapeKey = 'mapPinShape';
  static const String _listIconShapeKey = 'listIconShape';
  static const String _showRegionPinOutlineKey = 'showRegionPinOutline';
  static const String _regionPinShapeKey = 'regionPinShape';
  static const String _regionPinOutlineWidthKey = 'regionPinOutlineWidth';
  static const String _regionPinShapeStrokeWidthKey =
      'regionPinShapeStrokeWidth';
  static const String _showRegionDistrictNamesKey = 'showRegionDistrictNames';
  static const String _regionPinColorKey = 'regionPinColor';
  static const String _regionOutlineColorKey = 'regionOutlineColor';
  static const String _regionNameColorKey = 'regionNameColor';
  static const String _themeModeKey = 'themeMode';
  static const String _exportPathKey = 'exportPath';

  // --- WALLPAPER & BACKGROUND KEYS ---
  static const String _wallpaperModeKey =
      'wallpaperMode'; // 'static', 'slideshow', 'solid', 'gradient', 'default'
  static const String _slideshowBuildingPathKey = 'slideshowBuildingPath';
  static const String _slideshowSpeedKey = 'slideshowSpeedSeconds';
  static const String _slideshowTransitionDurationKey =
      'slideshowTransitionDurationSeconds';
  static const String _wallpaperFitKey = 'wallpaperFit';
  static const String _wallpaperPathKey = 'wallpaperPath';

  // --- SOLID/GRADIENT/BLUR KEYS ---
  static const String _solidColorKey = 'solidColor';
  static const String _gradientColor1Key = 'gradientColor1';
  static const String _gradientColor2Key = 'gradientColor2';
  static const String _blurStrengthKey = 'blurStrength';
  // --- END KEYS ---

  // --- STATIC VARIABLES ---
  static String? baseBuildingsPath;
  static String mapPinShape = 'Bulat';
  static String listIconShape = 'Bulat';
  static bool showRegionPinOutline = true;
  static String regionPinShape = 'Bulat';
  static double regionPinOutlineWidth = 2.0;
  static double regionPinShapeStrokeWidth = 0.0;
  static bool showRegionDistrictNames = true;
  static int regionPinColor = Colors.blue.value;
  static int regionOutlineColor = Colors.white.value;
  static int regionNameColor = Colors.white.value;
  static String? exportPath;
  static String? wallpaperPath;

  // --- WALLPAPER & BACKGROUND VARIABLES ---
  static String wallpaperMode = 'default'; // Diubah dari wallpaperType
  static String? slideshowBuildingPath;
  static double slideshowSpeedSeconds = 10.0;
  static double slideshowTransitionDurationSeconds = 1.0;
  static String wallpaperFit = 'cover';

  // --- SOLID/GRADIENT/BLUR VARIABLES ---
  static int solidColor = Colors.grey.shade900.value; // Default dark
  static int gradientColor1 = Colors.blue.value;
  static int gradientColor2 = Colors.deepPurple.value;
  static double blurStrength = 5.0; // Default blur

  static ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  // --- END STATIC VARIABLES ---

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseBuildingsPath = prefs.getString(_basePathKey);
    mapPinShape = prefs.getString(_mapPinShapeKey) ?? 'Bulat';
    listIconShape = prefs.getString(_listIconShapeKey) ?? 'Bulat';
    showRegionPinOutline = prefs.getBool(_showRegionPinOutlineKey) ?? true;
    regionPinShape = prefs.getString(_regionPinShapeKey) ?? 'Bulat';
    regionPinOutlineWidth = prefs.getDouble(_regionPinOutlineWidthKey) ?? 2.0;
    regionPinShapeStrokeWidth =
        prefs.getDouble(_regionPinShapeStrokeWidthKey) ?? 0.0;
    showRegionDistrictNames =
        prefs.getBool(_showRegionDistrictNamesKey) ?? true;

    regionPinColor = prefs.getInt(_regionPinColorKey) ?? Colors.blue.value;
    regionOutlineColor =
        prefs.getInt(_regionOutlineColorKey) ?? Colors.white.value;
    regionNameColor = prefs.getInt(_regionNameColorKey) ?? Colors.white.value;

    final themeString = prefs.getString(_themeModeKey) ?? 'system';
    themeMode.value = _getThemeModeFromString(themeString);

    exportPath = prefs.getString(_exportPathKey);

    // Load Wallpaper/Background Settings
    wallpaperPath = prefs.getString(_wallpaperPathKey);
    wallpaperMode = prefs.getString(_wallpaperModeKey) ?? 'default';
    slideshowBuildingPath = prefs.getString(_slideshowBuildingPathKey);
    slideshowSpeedSeconds = prefs.getDouble(_slideshowSpeedKey) ?? 10.0;
    slideshowTransitionDurationSeconds =
        prefs.getDouble(_slideshowTransitionDurationKey) ?? 1.0;
    wallpaperFit = prefs.getString(_wallpaperFitKey) ?? 'cover';

    // Load Solid/Gradient/Blur Settings
    solidColor = prefs.getInt(_solidColorKey) ?? Colors.grey.shade900.value;
    gradientColor1 = prefs.getInt(_gradientColor1Key) ?? Colors.blue.value;
    gradientColor2 =
        prefs.getInt(_gradientColor2Key) ?? Colors.deepPurple.value;
    blurStrength = prefs.getDouble(_blurStrengthKey) ?? 5.0;
  }

  // --- SAVE FUNCTIONS (BARU & DIUBAH) ---

  // Mengatur Mode Background (Solid, Gradient, dll.)
  static Future<void> saveBackgroundMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperModeKey, mode);
    wallpaperMode = mode;
    // Bersihkan path gambar jika mode diubah ke non-gambar/slideshow
    if (mode != 'static' && mode != 'slideshow') {
      await prefs.remove(_wallpaperPathKey);
      await prefs.remove(_slideshowBuildingPathKey);
      wallpaperPath = null;
      slideshowBuildingPath = null;
    }
  }

  // Mengatur Warna Solid
  static Future<void> saveSolidColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_solidColorKey, colorValue);
    solidColor = colorValue;
  }

  // Mengatur Warna Gradient
  static Future<void> saveGradientColor1(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gradientColor1Key, colorValue);
    gradientColor1 = colorValue;
  }

  static Future<void> saveGradientColor2(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gradientColor2Key, colorValue);
    gradientColor2 = colorValue;
  }

  // Mengatur Kekuatan Blur
  static Future<void> saveBlurStrength(double strength) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_blurStrengthKey, strength);
    blurStrength = strength;
  }

  // Mengatur Mode Tampilan Gambar (Fit)
  static Future<void> saveWallpaperFit(String fit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperFitKey, fit);
    wallpaperFit = fit;
  }

  // Mengatur Wallpaper Statis (Mengubah Mode)
  static Future<void> saveStaticWallpaper(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_wallpaperPathKey);
      await prefs.setString(_wallpaperModeKey, 'default');
    } else {
      await prefs.setString(_wallpaperPathKey, path);
      await prefs.setString(_wallpaperModeKey, 'static');
    }
    wallpaperPath = path;
    slideshowBuildingPath = null;
  }

  // Mengatur Slideshow (Mengubah Mode)
  static Future<void> saveSlideshowSettings({
    required String buildingPath,
    required double speed,
    required double transitionDuration,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_wallpaperModeKey, 'slideshow');
    await prefs.setString(_slideshowBuildingPathKey, buildingPath);
    await prefs.setDouble(_slideshowSpeedKey, speed);
    await prefs.setDouble(_slideshowTransitionDurationKey, transitionDuration);

    await prefs.remove(_wallpaperPathKey);

    wallpaperMode = 'slideshow';
    slideshowBuildingPath = buildingPath;
    slideshowSpeedSeconds = speed;
    slideshowTransitionDurationSeconds = transitionDuration;
    wallpaperPath = null;
  }

  // Menghapus Wallpaper/Background (Mengubah Mode ke Default)
  static Future<void> clearWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperModeKey, 'default');
    await prefs.remove(_wallpaperPathKey);
    await prefs.remove(_slideshowBuildingPathKey);

    wallpaperMode = 'default';
    wallpaperPath = null;
    slideshowBuildingPath = null;
  }

  // --- FUNGSI SAVE LAINNYA (Telah ada) ---

  static Future<void> saveExportPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportPathKey, path);
    exportPath = path;
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = mode;
    await prefs.setString(_themeModeKey, mode.toString().split('.').last);
  }

  static Future<void> saveBaseBuildingsPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_basePathKey, path);
    baseBuildingsPath = path;
  }

  static Future<void> saveMapPinShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapPinShapeKey, shape);
    mapPinShape = shape;
  }

  static Future<void> saveListIconShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listIconShapeKey, shape);
    listIconShape = shape;
  }

  static Future<void> saveShowRegionPinOutline(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showRegionPinOutlineKey, value);
    showRegionPinOutline = value;
  }

  static Future<void> saveRegionPinShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionPinShapeKey, shape);
    regionPinShape = shape;
  }

  static Future<void> saveRegionPinOutlineWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_regionPinOutlineWidthKey, width);
    regionPinOutlineWidth = width;
  }

  static Future<void> saveRegionPinShapeStrokeWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_regionPinShapeStrokeWidthKey, width);
    regionPinShapeStrokeWidth = width;
  }

  static Future<void> saveShowRegionDistrictNames(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showRegionDistrictNamesKey, value);
    showRegionDistrictNames = value;
  }

  static Future<void> saveRegionPinColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_regionPinColorKey, colorValue);
    regionPinColor = colorValue;
  }

  static Future<void> saveRegionOutlineColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_regionOutlineColorKey, colorValue);
    regionOutlineColor = colorValue;
  }

  static Future<void> saveRegionNameColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_regionNameColorKey, colorValue);
    regionNameColor = colorValue;
  }

  static ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
