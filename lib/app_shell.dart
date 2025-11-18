// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/building/presentation/management/building_management_page.dart';
import 'package:mind_palace_manager/features/settings/settings_page.dart';
// --- BARU: Import AppSettings ---
import 'package:mind_palace_manager/app_settings.dart';

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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Utama')),
      body: Center(
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              label: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}
