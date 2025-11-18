// lib/app_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan pengaturan global (path) agar bisa diakses
/// oleh semua fitur.
class AppSettings {
  /// Kunci untuk menyimpan path di SharedPreferences
  static const String _basePathKey = 'baseBuildingsPath';

  // --- DIPERBARUI ---
  /// Kunci untuk menyimpan bentuk pin Peta
  static const String _mapPinShapeKey = 'mapPinShape'; // <-- Diganti nama
  /// Kunci untuk menyimpan bentuk ikon Daftar
  static const String _listIconShapeKey = 'listIconShape'; // <-- Baru
  // --- SELESAI DIPERBARUI ---

  /// Path lengkap ke folder 'buildings' (cth: /home/user/Dokumen/buildings)
  /// Ini akan diisi saat aplikasi dimulai.
  static String? baseBuildingsPath;

  // --- DIPERBARUI ---
  /// Bentuk pin Peta: 'Bulat', 'Kotak'
  static String mapPinShape = 'Bulat'; // <-- Diganti nama
  /// Bentuk ikon Daftar: 'Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)'
  static String listIconShape = 'Bulat'; // <-- Baru
  // --- SELESAI DIPERBARUI ---

  /// Memuat path yang tersimpan dari SharedPreferences ke variabel statis.
  /// Panggil ini saat aplikasi dimulai.
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseBuildingsPath = prefs.getString(_basePathKey);

    // --- DIPERBARUI ---
    // Muat pengaturan bentuk pin Peta, default ke 'Bulat'
    mapPinShape = prefs.getString(_mapPinShapeKey) ?? 'Bulat';
    // Muat pengaturan bentuk ikon Daftar, default ke 'Bulat'
    listIconShape = prefs.getString(_listIconShapeKey) ?? 'Bulat';
    // --- SELESAI DIPERBARUI ---
  }

  /// Menyimpan path baru ke SharedPreferences dan memperbarui variabel statis.
  static Future<void> saveBaseBuildingsPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_basePathKey, path);
    baseBuildingsPath = path; // Perbarui juga variabel statis saat ini
  }

  // --- FUNGSI DIPERBARUI ---
  /// Menyimpan bentuk pin Peta baru ke SharedPreferences
  static Future<void> saveMapPinShape(String shape) async {
    // <-- Diganti nama
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapPinShapeKey, shape);
    mapPinShape = shape; // Perbarui variabel statis
  }
  // --- SELESAI DIPERBARUI ---

  // --- FUNGSI BARU ---
  /// Menyimpan bentuk ikon Daftar baru ke SharedPreferences
  static Future<void> saveListIconShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listIconShapeKey, shape);
    listIconShape = shape; // Perbarui variabel statis
  }

  // --- SELESAI FUNGSI BARU ---
}
