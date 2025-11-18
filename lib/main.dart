// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_shell.dart';
import 'package:mind_palace_manager/app_settings.dart'; // <-- Impor AppSettings

// --- TAMBAHAN ---
// Impor helper izin yang baru dibuat
import 'package:mind_palace_manager/permission_helper.dart';
// --- SELESAI TAMBAHAN ---

Future<void> main() async {
  // Pastikan binding Flutter siap sebelum memanggil SharedPreferences
  WidgetsFlutterBinding.ensureInitialized(); // <-- Tambahan penting

  // --- TAMBAHAN ---
  // Minta izin penyimpanan sebelum memuat pengaturan atau menjalankan app
  // Ini penting untuk Android
  await checkAndRequestPermissions();
  // --- SELESAI TAMBAHAN ---

  // Muat pengaturan (path folder) dari penyimpanan persisten
  await AppSettings.loadSettings(); // <-- Tambahan penting

  // Jalankan aplikasi setelah pengaturan dimuat
  runApp(const MainApp());
}
