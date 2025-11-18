// lib/app_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan pengaturan global (path) agar bisa diakses
/// oleh semua fitur.
class AppSettings {
  /// Kunci untuk menyimpan path di SharedPreferences
  static const String _basePathKey = 'baseBuildingsPath';

  // --- TAMBAHAN ---
  /// Kunci untuk menyimpan bentuk ikon
  static const String _iconShapeKey = 'iconShape';
  // --- SELESAI TAMBAHAN ---

  /// Path lengkap ke folder 'buildings' (cth: /home/user/Dokumen/buildings)
  /// Ini akan diisi saat aplikasi dimulai.
  static String? baseBuildingsPath;

  // --- TAMBAHAN ---
  /// Bentuk ikon global: 'Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)'
  static String iconShape = 'Bulat'; // Default
  // --- SELESAI TAMBAHAN ---

  /// Memuat path yang tersimpan dari SharedPreferences ke variabel statis.
  /// Panggil ini saat aplikasi dimulai.
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseBuildingsPath = prefs.getString(_basePathKey);

    // --- TAMBAHAN ---
    // Muat pengaturan bentuk ikon, default ke 'Bulat'
    iconShape = prefs.getString(_iconShapeKey) ?? 'Bulat';
    // --- SELESAI TAMBAHAN ---
  }

  /// Menyimpan path baru ke SharedPreferences dan memperbarui variabel statis.
  static Future<void> saveBaseBuildingsPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_basePathKey, path);
    baseBuildingsPath = path; // Perbarui juga variabel statis saat ini
  }

  // --- FUNGSI BARU ---
  /// Menyimpan bentuk ikon baru ke SharedPreferences
  static Future<void> saveIconShape(String shape) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_iconShapeKey, shape);
    iconShape = shape; // Perbarui variabel statis
  }
  // --- SELESAI FUNGSI BARU ---
}