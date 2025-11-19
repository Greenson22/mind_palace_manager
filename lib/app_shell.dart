// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/building/presentation/management/building_management_page.dart';
import 'package:mind_palace_manager/features/settings/settings_page.dart';
// --- BARU: Import AppSettings ---
import 'package:mind_palace_manager/app_settings.dart';
// --- PERBAIKAN: Hanya pertahankan import yang dibutuhkan untuk display ---
import 'dart:io';
// --- SELESAI PERBAIKAN ---

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- BARU: Bungkus dengan ValueListenableBuilder ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mind Palace Manager',

          // --- Konfigurasi Tema ---
          themeMode: currentThemeMode,

          // Tema Terang (Light)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          ),

          // Tema Gelap (Dark)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed:
                Colors.blue, // Warna dasar tetap biru agar konsisten
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          ),

          home: const DashboardPage(),
        );
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Metode ini diperlukan untuk memicu rebuild DashboardPage saat kembali dari SettingsPage
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    ).then(
      (_) => setState(() {
        // Rebuild untuk memuat wallpaper baru
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan widget latar belakang
    Widget backgroundWidget = AppSettings.wallpaperPath != null
        ? Image.file(
            File(AppSettings.wallpaperPath!),
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Theme.of(context).colorScheme.surface),
          )
        : Container(
            color: Theme.of(context).colorScheme.surface,
          ); // Latar Default

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Utama'),
        actions: const [], // Tombol Wallpaper dipindahkan ke Settings
      ),
      // Susun konten di atas latar belakang
      body: Stack(
        children: [
          // 1. Background (Wallpaper)
          Positioned.fill(child: backgroundWidget),

          // 2. Overlay untuk keterbacaan
          Positioned.fill(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(
                      0.5,
                    ) // Overlay gelap untuk dark mode
                  : Colors.white.withOpacity(
                      0.7,
                    ), // Overlay terang untuk light mode
            ),
          ),

          // 3. Foreground Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon besar dekoratif
                Icon(
                  Icons.castle_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.business),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuildingManagementPage(),
                      ),
                    );
                  },
                  label: const Text('Kelola Distrik & Bangunan'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  onPressed:
                      _openSettings, // Panggil metode dengan setState after pop
                  label: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
