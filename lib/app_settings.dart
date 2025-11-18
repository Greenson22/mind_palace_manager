// lib/app_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _basePathKey = 'baseBuildingsPath';
  static const String _mapPinShapeKey = 'mapPinShape';
  static const String _listIconShapeKey = 'listIconShape';
  static const String _showRegionPinOutlineKey = 'showRegionPinOutline';
  // --- BARU ---
  static const String _regionPinShapeKey = 'regionPinShape';

  static String? baseBuildingsPath;
  static String mapPinShape = 'Bulat';
  static String listIconShape = 'Bulat';
  static bool showRegionPinOutline = true;
  // --- BARU: Default Bulat ---
  static String regionPinShape = 'Bulat';

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseBuildingsPath = prefs.getString(_basePathKey);
    mapPinShape = prefs.getString(_mapPinShapeKey) ?? 'Bulat';
    listIconShape = prefs.getString(_listIconShapeKey) ?? 'Bulat';
    showRegionPinOutline = prefs.getBool(_showRegionPinOutlineKey) ?? true;
    // --- BARU ---
    regionPinShape = prefs.getString(_regionPinShapeKey) ?? 'Bulat';
  }

  // ... (Fungsi save yang lain tetap sama)

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

  // --- BARU ---
  static Future<void> saveRegionPinShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionPinShapeKey, shape);
    regionPinShape = shape;
  }
}
