// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_shell.dart';
import 'package:mind_palace_manager/app_settings.dart'; // <-- Impor AppSettings

Future<void> main() async {
  // Pastikan binding Flutter siap sebelum memanggil SharedPreferences
  WidgetsFlutterBinding.ensureInitialized(); // <-- Tambahan penting

  // Muat pengaturan (path folder) dari penyimpanan persisten
  await AppSettings.loadSettings(); // <-- Tambahan penting

  // Jalankan aplikasi setelah pengaturan dimuat
  runApp(const MainApp());
}
