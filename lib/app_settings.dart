// lib/app_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // --- KEYS EXISTING ---
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

  // --- WALLPAPER KEYS ---
  static const String _wallpaperModeKey = 'wallpaperMode';
  static const String _slideshowBuildingPathKey = 'slideshowBuildingPath';
  static const String _slideshowSourceTypeKey = 'slideshowSourceType';
  static const String _slideshowSpeedKey = 'slideshowSpeedSeconds';
  static const String _slideshowTransitionDurationKey =
      'slideshowTransitionDurationSeconds';
  static const String _wallpaperFitKey = 'wallpaperFit';
  static const String _wallpaperPathKey = 'wallpaperPath';
  static const String _solidColorKey = 'solidColor';
  static const String _gradientColor1Key = 'gradientColor1';
  static const String _gradientColor2Key = 'gradientColor2';
  static const String _blurStrengthKey = 'blurStrength';
  static const String _containmentBackgroundColorKey =
      'containmentBackgroundColor';
  static const String _backgroundOverlayOpacityKey = 'backgroundOverlayOpacity';

  // --- OBJECT VISIBILITY KEYS ---
  static const String _defaultShowObjectIconsKey = 'defaultShowObjectIcons';
  static const String _objectIconOpacityKey = 'objectIconOpacity';
  static const String _interactableWhenHiddenKey = 'interactableWhenHidden';

  // --- NAVIGATION ARROW KEYS (BARU) ---
  static const String _showNavigationArrowsKey = 'showNavigationArrows';
  static const String _navigationArrowOpacityKey = 'navigationArrowOpacity';
  static const String _navigationArrowScaleKey = 'navigationArrowScale';
  static const String _navigationArrowColorKey = 'navigationArrowColor';

  // --- VARIABLES ---
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

  static String wallpaperMode = 'default';
  static String? slideshowBuildingPath;
  static String slideshowSourceType = 'building';
  static double slideshowSpeedSeconds = 10.0;
  static double slideshowTransitionDurationSeconds = 1.0;
  static String wallpaperFit = 'cover';

  static ValueNotifier<int> solidColor = ValueNotifier(
    Colors.grey.shade900.value,
  );
  static int gradientColor1 = Colors.blue.value;
  static int gradientColor2 = Colors.deepPurple.value;
  static ValueNotifier<double> blurStrength = ValueNotifier(5.0);
  static ValueNotifier<int> containmentBackgroundColor = ValueNotifier(
    Colors.black.value,
  );

  // --- PERUBAHAN DI SINI: Menggunakan ValueNotifier ---
  static ValueNotifier<double> backgroundOverlayOpacity = ValueNotifier(0.5);

  static ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static bool defaultShowObjectIcons = true;
  static double objectIconOpacity = 1.0;
  static bool interactableWhenHidden = true;

  // --- NAVIGATION VARIABLES (BARU) ---
  static bool showNavigationArrows = true;
  static double navigationArrowOpacity = 0.9; // Default agak transparan
  static double navigationArrowScale = 1.5; // Default ukuran sedang
  static int navigationArrowColor = 0xFFFFFFFF; // Default Putih

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

    wallpaperPath = prefs.getString(_wallpaperPathKey);
    wallpaperMode = prefs.getString(_wallpaperModeKey) ?? 'default';
    slideshowBuildingPath = prefs.getString(_slideshowBuildingPathKey);
    slideshowSourceType =
        prefs.getString(_slideshowSourceTypeKey) ?? 'building';
    slideshowSpeedSeconds = prefs.getDouble(_slideshowSpeedKey) ?? 10.0;
    slideshowTransitionDurationSeconds =
        prefs.getDouble(_slideshowTransitionDurationKey) ?? 1.0;
    wallpaperFit = prefs.getString(_wallpaperFitKey) ?? 'cover';

    solidColor.value =
        prefs.getInt(_solidColorKey) ?? Colors.grey.shade900.value;
    gradientColor1 = prefs.getInt(_gradientColor1Key) ?? Colors.blue.value;
    gradientColor2 =
        prefs.getInt(_gradientColor2Key) ?? Colors.deepPurple.value;
    blurStrength.value = prefs.getDouble(_blurStrengthKey) ?? 5.0;
    containmentBackgroundColor.value =
        prefs.getInt(_containmentBackgroundColorKey) ?? Colors.black.value;

    // --- PERUBAHAN DI SINI: Mengakses .value ---
    backgroundOverlayOpacity.value =
        prefs.getDouble(_backgroundOverlayOpacityKey) ?? 0.5;

    defaultShowObjectIcons = prefs.getBool(_defaultShowObjectIconsKey) ?? true;
    objectIconOpacity = prefs.getDouble(_objectIconOpacityKey) ?? 1.0;
    interactableWhenHidden = prefs.getBool(_interactableWhenHiddenKey) ?? true;

    // --- LOAD NAVIGATION SETTINGS ---
    showNavigationArrows = prefs.getBool(_showNavigationArrowsKey) ?? true;
    navigationArrowOpacity = prefs.getDouble(_navigationArrowOpacityKey) ?? 0.9;
    navigationArrowScale = prefs.getDouble(_navigationArrowScaleKey) ?? 1.5;
    navigationArrowColor = prefs.getInt(_navigationArrowColorKey) ?? 0xFFFFFFFF;
  }

  // --- SAVE FUNCTIONS ---

  static Future<void> saveBackgroundMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperModeKey, mode);
    wallpaperMode = mode;
    if (mode != 'static' && mode != 'slideshow') {
      await prefs.remove(_wallpaperPathKey);
      await prefs.remove(_slideshowBuildingPathKey);
      wallpaperPath = null;
      slideshowBuildingPath = null;
    }
  }

  static Future<void> saveSlideshowSettings({
    required String path,
    required String sourceType,
    required double speed,
    required double transitionDuration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperModeKey, 'slideshow');
    await prefs.setString(_slideshowBuildingPathKey, path);
    await prefs.setString(_slideshowSourceTypeKey, sourceType);
    await prefs.setDouble(_slideshowSpeedKey, speed);
    await prefs.setDouble(_slideshowTransitionDurationKey, transitionDuration);
    await prefs.remove(_wallpaperPathKey);

    wallpaperMode = 'slideshow';
    slideshowBuildingPath = path;
    slideshowSourceType = sourceType;
    slideshowSpeedSeconds = speed;
    slideshowTransitionDurationSeconds = transitionDuration;
    wallpaperPath = null;
  }

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

  static Future<void> saveSolidColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_solidColorKey, colorValue);
    solidColor.value = colorValue;
  }

  static Future<void> saveContainmentBackgroundColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_containmentBackgroundColorKey, colorValue);
    containmentBackgroundColor.value = colorValue;
  }

  static Future<void> saveBackgroundOverlayOpacity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_backgroundOverlayOpacityKey, value);

    // --- PERUBAHAN DI SINI: Mengakses .value ---
    backgroundOverlayOpacity.value = value;
  }

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

  static Future<void> saveBlurStrength(double strength) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_blurStrengthKey, strength);
    blurStrength.value = strength;
  }

  static Future<void> saveWallpaperFit(String fit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperFitKey, fit);
    wallpaperFit = fit;
  }

  static Future<void> clearWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperModeKey, 'default');
    await prefs.remove(_wallpaperPathKey);
    await prefs.remove(_slideshowBuildingPathKey);
    wallpaperMode = 'default';
    wallpaperPath = null;
    slideshowBuildingPath = null;
  }

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

  static Future<void> saveDefaultShowObjectIcons(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_defaultShowObjectIconsKey, value);
    defaultShowObjectIcons = value;
  }

  static Future<void> saveObjectIconOpacity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_objectIconOpacityKey, value);
    objectIconOpacity = value;
  }

  static Future<void> saveInteractableWhenHidden(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_interactableWhenHiddenKey, value);
    interactableWhenHidden = value;
  }

  static Future<void> saveShowNavigationArrows(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNavigationArrowsKey, value);
    showNavigationArrows = value;
  }

  static Future<void> saveNavigationArrowOpacity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_navigationArrowOpacityKey, value);
    navigationArrowOpacity = value;
  }

  static Future<void> saveNavigationArrowScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_navigationArrowScaleKey, value);
    navigationArrowScale = value;
  }

  static Future<void> saveNavigationArrowColor(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_navigationArrowColorKey, value);
    navigationArrowColor = value;
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
