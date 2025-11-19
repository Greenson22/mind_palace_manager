// lib/app_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // ... keys yang sudah ada ...
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

  // --- BARU: Key untuk Export Path ---
  static const String _exportPathKey = 'exportPath';

  // ... variabel statis yang sudah ada ...
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

  // --- BARU: Variabel statis untuk Export Path ---
  static String? exportPath;

  static ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

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

    // --- BARU: Load Export Path ---
    exportPath = prefs.getString(_exportPathKey);
  }

  // --- BARU: Fungsi Save Export Path ---
  static Future<void> saveExportPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportPathKey, path);
    exportPath = path;
  }

  // ... fungsi save yang lama ...

  // --- BARU: Fungsi Save Tema ---
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = mode; // Update notifier
    await prefs.setString(_themeModeKey, mode.toString().split('.').last);
  }

  // Helper konversi String ke ThemeMode
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
}
